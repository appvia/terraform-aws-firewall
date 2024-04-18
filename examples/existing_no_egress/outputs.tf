
output "routing_configuration" {
  description = "The routing configuration."
  value       = module.inspection.routing_configuration
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets."
  value       = module.inspection.private_subnet_ids
}

output "private_subnet_id_by_az" {
  description = "The private subnet IDs by availability zone."
  value       = module.inspection.private_subnet_id_by_az
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = module.inspection.public_subnet_ids
}

output "transit_subnet_ids" {
  description = "The IDs of the transit subnets."
  value       = module.inspection.transit_subnet_ids
}

output "ram_principals" {
  description = "The principals to share the firewall with."
  value       = module.inspection.ram_principals
}

output "policy_variables" {
  description = "The policy variables to associate with the firewall."
  value       = module.inspection.policy_variables
}

output "firewall_rule_groups" {
  description = "The rule groups to associate with the firewall."
  value       = module.inspection.firewall_rule_groups
}

output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.inspection.vpc_id
}

output "transit_route_table_by_az" {
  description = "The transit route table by availability zone."
  value       = module.inspection.transit_route_table_by_az
}

output "transit_attachment_id" {
  description = "The ID of the transit gateway attachment."
  value       = module.inspection.transit_attachment_id
}
