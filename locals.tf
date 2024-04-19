
locals {
  ## Indicates if we are creating the vpc or reusing an existing one 
  enable_vpc_creation = var.vpc_id == "" ? true : false
  ## The currente region we are running against 
  region = data.aws_region.current.name
  ## The account id we are running against
  account_id = data.aws_caller_identity.current.account_id
  ## Transit Gateway Route Table IDs for the VPC 
  transit_route_table_ids = local.enable_vpc_creation ? module.vpc[0].transit_route_table_ids : var.transit_route_table_ids
  ## Public Route Table IDs for the VPC 
  public_route_table_ids = local.enable_vpc_creation ? module.vpc[0].public_route_table_ids : var.public_route_table_ids
  ## Private subnet IDs for the VPC 
  private_subnet_id_by_az = local.enable_vpc_creation ? module.vpc[0].private_subnet_id_by_az : var.private_subnet_id_by_az
  ## Map of transit route table IDs by AZ 
  transit_route_table_by_az = local.enable_vpc_creation ? module.vpc[0].transit_route_table_by_az : var.transit_route_table_by_az
  # Mode for the NAT Gateway
  nat_gateway_mode = var.enable_egress ? "all_azs" : "none"
  ## The VPC ID for the inspection service, either created or provided 
  vpc_id = local.enable_vpc_creation ? module.vpc[0].vpc_id : var.vpc_id
  ## configuration for egress inspection 
  route_configuration_with_egress = var.enable_egress ? {
    centralized_inspection_with_egress = {
      connectivity_subnet_route_tables = local.transit_route_table_ids
      public_subnet_route_tables       = local.public_route_table_ids
      network_cidr_blocks              = var.network_cidr_blocks
  } } : {}
  ## Route configuration for inspection without egress 
  route_configuration_without_egress = var.enable_egress ? {} : {
    centralized_inspection_without_egress = {
      connectivity_subnet_route_tables = local.transit_route_table_by_az
    }
  }
  # Choose the appropriate route configuration based on whether egress is enabled
  routing_configuration = merge(local.route_configuration_with_egress, local.route_configuration_without_egress)
  ## The arn for the kms key if we are reusing an existing one  
  existing_kms_arn = var.cloudwatch_kms != "" ? data.aws_kms_key.current[0].arn : null
  ## The arn for the created kms key if we are creating one 
  created_kms_arn = var.create_kms_key ? aws_kms_key.current[0].arn : null
  ## The arn for the kms key, create, existing or none
  kms_key_arn = try(coalesce(local.created_kms_arn, local.existing_kms_arn), null)
  ## The firewall rules for the policy, this is the constructed rules with any additional_rule_groups 
  ## added to the end
  builtin_firewall_rule_groups = [
    {
      priority = 1000
      arn      = try(aws_networkfirewall_rule_group.stateful[0].arn, null)
    }
  ]
  ## We always add the home_net to the policy variables, to ensure the variable is made accessible to 
  ## suricata rules
  firewall_policy_variables = merge({ home_net = var.network_cidr_blocks }, var.policy_variables)
  ## We merge all the firewall rules into a single string, this is used to create the firewall policy 
  firewall_merged_rules = join("\n", [
    for x in coalesce(var.firewall_rules, []) : format("# --- %s\n%s", x.name, x.content)
  ])

  ## The s3 dashboard url for the cloudwatch dashboard, which is passed to the cloudformation stack
  dashboard_url = format("https://%s.s3.%s.amazonaws.com/%s", var.dashboard_bucket, local.region, var.dashboard_key)
}
