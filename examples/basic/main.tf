#
## Provisions a central inspection vpc 
#

locals {
  firewall_rules = {
    "default.rules" : file("${path.module}/rules/default.rules"),
  }
}

## Provision the inspection vpc
module "inspection" {
  source  = "appvia/inspection/aws"
  version = "0.0.1"

  availability_zones           = var.availability_zones
  create_kms_key               = var.create_kms_key
  cloudwatch_kms               = var.cloudwatch_kms
  cloudwatch_retention_in_days = var.cloudwatch_retention_in_days
  enable_dashboard             = var.enable_dashboard
  ip_prefixes                  = var.ip_prefixes
  name                         = var.name
  firewall_rules               = local.firewall_rules
  ram_principals               = var.ram_principals
  policy_variables             = var.policy_variables
  tags                         = var.tags
  transit_gateway_name         = var.transit_gateway_name
  vpc_cidr                     = var.vpc_cidr
}

