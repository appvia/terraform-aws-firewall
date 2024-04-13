
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
