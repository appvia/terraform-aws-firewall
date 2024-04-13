locals {
  # We add the default stateful rule group to the list of additional rule groups
  firewall_rule_groups = concat([
    {
      priority = 1000
      name     = aws_networkfirewall_rule_group.stateful.name
    }
  ], var.additional_rule_groups)
  # We merge the override for HOME_NET with the default policy variables
  policy_variables = merge({ home_net = var.network_cidr_blocks }, var.policy_variables)
  # Merge the contents of the rules into a single string
  merged_rules = join("\n", [
    for filepath in var.firewall_rules : format("# --- %s\n%s", filepath, file("${path.module}/${filepath}"))
  ])
}

## Provision any ip-sets that have been defined
resource "aws_ec2_managed_prefix_list" "this" {
  for_each = {
    for k, v in var.ip_prefixes : k.name => v
  }

  name           = each.value.name
  address_family = each.value.address_family
  max_entries    = each.value.max_entries
  tags           = merge(var.tags, { "Name" : each.value.name })

  dynamic "entry" {
    for_each = each.value.entries

    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }
}

## Network Firewall Policy
resource "aws_networkfirewall_firewall_policy" "this" {
  depends_on = [aws_networkfirewall_rule_group.stateful]

  name        = "firewall-${var.name}"
  description = "Firewall Policy for ${var.name} environment"
  tags        = var.tags

  firewall_policy {
    policy_variables {
      rule_variables {
        key = "HOME_NET"
        ip_set {
          definition = var.network_cidr_blocks
        }
      }
    }

    dynamic "stateful_rule_group_reference" {
      for_each = {
        for x in local.firewall_rule_groups : x.name => x
      }

      content {
        priority     = stateful_rule_group_reference.value.priority
        resource_arn = "arn:aws:network-firewall:${local.region}:${local.account_id}:stateful-rulegroup/${stateful_rule_group_reference.value.name}"
      }
    }

    stateful_default_actions = ["aws:drop_established", "aws:alert_established"]
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
  }
}

## Provision any RAM shares of the firewall policy
resource "aws_ram_resource_share" "this" {
  count = length(var.ram_principals) > 0 ? 1 : 0

  name                      = "firewall-policy-${var.name}"
  allow_external_principals = false
  tags                      = var.tags
}

## Associate the firewall policy with the RAM share
resource "aws_ram_resource_association" "this" {
  count = length(var.ram_principals) > 0 ? 1 : 0

  resource_arn       = aws_networkfirewall_firewall_policy.this.arn
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

## Share the firewall policy with the principals
resource "aws_ram_principal_association" "this" {
  for_each = var.ram_principals

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

## Network Firewall Rule Group for Stateful Rules
resource "aws_networkfirewall_rule_group" "stateful" {
  name        = "stateful-${var.name}"
  capacity    = var.stateful_capacity
  description = "Stateful rule group for ${var.name} environment"
  tags        = merge(var.tags, { "Name" : "stateful-${var.name}" })
  type        = "STATEFUL"

  rule_group {
    rule_variables {
      dynamic "ip_sets" {
        for_each = var.policy_variables

        content {
          key = upper(ip_sets.key)
          ip_set {
            definition = ip_sets.value
          }
        }
      }
    }

    reference_sets {
      dynamic "ip_set_references" {
        for_each = var.ip_prefixes != null ? var.ip_prefixes : {}

        content {
          key = upper(ip_set_references.key)
          ip_set_reference {
            reference_arn = "arn:aws:network-firewall:${var.region}:${local.account_id}:managed-prefix-list/${ip_set_references.value}"
          }
        }
      }
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }

    rules_source {
      rules_string = local.merged_rules
    }
  }
}
