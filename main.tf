
## Provision the VPC for the inspection service
module "vpc" {
  count   = var.vpc_id == "" ? 1 : 0
  source  = "appvia/network/aws"
  version = "0.3.0"

  availability_zones                    = var.availability_zones
  enable_nat_gateway                    = var.enable_egress
  enable_transit_gateway                = true
  enable_transit_gateway_appliance_mode = true
  name                                  = var.name
  nat_gateway_mode                      = local.nat_gateway_mode
  private_subnet_netmask                = var.private_subnet_netmask
  public_subnet_netmask                 = var.public_subnet_netmask
  tags                                  = var.tags
  transit_gateway_id                    = var.transit_gateway_id
  vpc_cidr                              = var.vpc_cidr

  transit_gateway_routes = {
    private = "10.0.0.0/8"
  }
}

## Provision the AWS Network Firewall service in the inspection VPC
module "network_firewall" {
  source  = "aws-ia/networkfirewall/aws"
  version = "1.0.1"

  network_firewall_description              = "Inspection VPC Firewall for ${var.name} environment"
  network_firewall_name                     = var.name
  network_firewall_policy                   = aws_networkfirewall_firewall_policy.this.arn
  network_firewall_policy_change_protection = var.enable_policy_change_protection
  network_firewall_subnet_change_protection = var.enable_subnet_change_protection
  number_azs                                = var.availability_zones
  routing_configuration                     = local.routing_configuration
  tags                                      = var.tags
  vpc_id                                    = local.vpc_id
  vpc_subnets                               = local.private_subnet_id_by_az

  logging_configuration = {
    alert_log = {
      cloudwatch_logs = {
        logGroupName = aws_cloudwatch_log_group.alert_log.name
      }
    }
    flow_log = {
      cloudwatch_logs = {
        logGroupName = aws_cloudwatch_log_group.flow_log.name
      }
    }
  }

  depends_on = [module.vpc]
}
