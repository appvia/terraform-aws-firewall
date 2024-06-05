mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = [
        "eu-west-1a",
        "eu-west-1b",
        "eu-west-1c"
      ]
    }
  }
}

run "basic" {
  command = plan

  variables {
    availability_zones = 3
    name               = "dev"
    tags = {
      Environment = "dev"
    }
    transit_gateway_id = "tgw-04ad8f026be8b7eb6"
    external_rule_groups = [
      {
        priority = 100
        arn      = "arn:aws:network-firewall:us-west-2:111122223333:stateful-rulegroup/domains"

      }
    ]
  }
}
