
output "private_subnet_ids" {
  description = "The IDs of the private subnets."
  value       = local.enable_vpc_creation ? module.vpc[0].private_subnet_ids : null
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = local.enable_vpc_creation ? module.vpc[0].public_subnet_ids : null
}

output "transit_subnet_ids" {
  description = "The IDs of the transit subnets."
  value       = local.enable_vpc_creation ? module.vpc[0].transit_subnet_ids : null
}

output "firewall_id" {
  description = "The ARN of the firewall."
  value       = module.network_firewall.aws_network_firewall.id
}

output "firewall_arn" {
  description = "The ARN of the firewall"
  value       = module.network_firewall.aws_network_firewall.arn
}

output "stateful_rule_group_id" {
  description = "The ID of the stateful rule group."
  value       = aws_networkfirewall_rule_group.stateful.id
}

output "ram_principals" {
  description = "The principals to share the firewall with."
  value       = var.ram_principals
}

output "policy_variables" {
  description = "The policy variables to associate with the firewall."
  value       = local.policy_variables
}

output "firewall_rule_groups" {
  description = "The rule groups to associate with the firewall."
  value       = local.firewall_rule_groups
}

output "vpc_id" {
  description = "The ID of the VPC."
  value       = local.enable_vpc_creation ? module.vpc[0].vpc_id : var.vpc_id
}

output "transit_attachment_id" {
  description = "The ID of the transit gateway attachment."
  value       = local.enable_vpc_creation ? module.vpc[0].transit_attachment_id : null
}
