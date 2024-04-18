
## First we provision the stateful rule group
resource "aws_networkfirewall_rule_group" "stateful" {
  count = var.external_rule_groups != null || var.firewall_rules == null ? 0 : 1

  name        = "stateful-${var.name}"
  capacity    = var.stateful_capacity
  description = "Stateful rule group for ${var.name} environment"
  tags        = merge(var.tags, { "Name" : "stateful-${var.name}" })
  type        = "STATEFUL"

  rule_group {
    rule_variables {
      dynamic "ip_sets" {
        for_each = local.firewall_policy_variables

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
            reference_arn = "arn:aws:network-firewall:${local.region}:${local.account_id}:managed-prefix-list/${ip_set_references.value}"
          }
        }
      }
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }

    rules_source {
      rules_string = local.firewall_merged_rules
    }
  }
}

## Next we provision a firewall policy, attaching the stateful rule group 
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

    # Add the stateful rule groups to the policy
    dynamic "stateful_rule_group_reference" {
      for_each = {
        for x in coalesce(var.external_rule_groups, local.builtin_firewall_rule_groups) : x.arn => x
      }

      content {
        priority     = stateful_rule_group_reference.value.priority
        resource_arn = stateful_rule_group_reference.value.arn
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

