#####################################################################################
# Terraform module examples are meant to show an _example_ on how to use a module
# per use-case. The code below should not be copied directly but referenced in order
# to build your own root module that invokes this module
#####################################################################################

locals {
  firewall_rules = {
    "default.rules" : file("${path.module}/rules/default.rules"),
  }
}

## Provision a vpc for the inspection firewall 
module "vpc" {
  source  = "appvia/network/aws"
  version = "0.2.0"

  availability_zones                    = 3
  enable_transit_gateway                = true
  enable_transit_gateway_appliance_mode = true
  name                                  = "existing"
  private_subnet_netmask                = 24
  tags                                  = var.tags
  transit_gateway_id                    = var.transit_gateway_id
  vpc_cidr                              = "100.64.0.0/21"
}

## Provision a inspection firewall, but with an existing vpc
module "inspection" {
  source = "../.."

  availability_zones = 3
  create_kms_key     = false
  name               = "existing"
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
}
