
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
