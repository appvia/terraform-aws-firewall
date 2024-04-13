#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

locals {
  firewall_rules = [
    {
      name    = "default.rules"
      content = file("${path.module}/rules/default.rules")
    },
  ]
}

## Provision a vpc for the inspection firewall 
module "vpc" {
  source  = "appvia/network/aws"
  version = "0.2.0"

  availability_zones                    = 3
  enable_transit_gateway                = true
  enable_transit_gateway_appliance_mode = true
  name                                  = var.name
  private_subnet_netmask                = var.private_subnet_netmask
  public_subnet_netmask                 = var.public_subnet_netmask
  tags                                  = var.tags
  transit_gateway_id                    = var.transit_gateway_id
  vpc_cidr                              = var.vpc_cidr
}

## Provision a inspection firewall, but with an existing vpc
module "inspection" {
  source = "../.."

  availability_zones = var.availability_zones
  create_kms_key     = var.create_kms_key
  enable_dashboard   = var.enable_dashboard
  enable_egress      = true
  name               = var.name
  firewall_rules     = local.firewall_rules
  ram_principals     = var.ram_principals
  tags               = var.tags
  transit_gateway_id = var.transit_gateway_id

  #
  ## The following variables are required for the inspection module (WITH egress support) 
  #
  private_subnet_id_by_az   = module.vpc.private_subnet_id_by_az
  public_route_table_ids    = module.vpc.public_route_table_ids
  transit_route_table_by_az = module.vpc.transit_route_table_by_az
  transit_route_table_ids   = module.vpc.transit_route_table_ids
  vpc_id                    = module.vpc.vpc_id

  depends_on = [module.vpc]
}
