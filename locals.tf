
locals {
  ## Indicates if we are creating the vpc or reusing an existing one 
  enable_vpc_creation = var.vpc_id == null ? false : true
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
    connectivity_subnet_route_tables = local.transit_route_table_by_az
  }
  # Choose the appropriate route configuration based on whether egress is enabled
  routing_configuration = merge(local.route_configuration_with_egress, local.route_configuration_without_egress)
  ## The KMS key used to encrypt the CloudWatch logs
  kms_key_arn = var.create_kms_key ? aws_kms_key.current[0].arn : data.aws_kms_key.current[0].arn
}
