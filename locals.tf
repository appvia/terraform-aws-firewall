
locals {
  private_subnet_ids = {
    for k, v in module.vpc.private_subnet_attributes_by_az : split("/", k)[1] => v.id if split("/", k)[0] == "private"
  }
  transit_subnet_ids = {
    for k, v in module.vpc.private_subnet_attributes_by_az : k => v.id if split("/", k)[0] == "transit_gateway"
  }
  public_subnet_ids = {
    for k, v in module.vpc.public_subnet_attributes_by_az : k => v.id
  }

  public_route_table_ids = {
    for k, v in module.vpc.rt_attributes_by_type_by_az.public : k => v.id
  }
  transit_route_table_ids = {
    for k, v in module.vpc.rt_attributes_by_type_by_az.transit_gateway : k => v.id
  }
  account_id = data.aws_caller_identity.current.account_id

  # Mode for the NAT Gateway
  nat_gateway_mode = var.enable_egress ? "all_azs" : "none"

  # Choose the appropriate route configuration based on whether egress is enabled
  routing_configuration = var.enable_egress ? {
    centralized_inspection_with_egress = {
      connectivity_subnet_route_tables = local.transit_route_table_ids
      public_subnet_route_tables       = local.public_route_table_ids
      network_cidr_blocks              = var.network_cidr_blocks
    }
    } : {
    connectivity_subnet_route_tables = { for k, v in module.vpc.rt_attributes_by_type_by_az.transit_gateway : k => v.id }
  }
}
