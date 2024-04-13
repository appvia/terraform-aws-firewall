
## Find the sts context
data "aws_caller_identity" "current" {}

## Find the transit gateway
data "aws_ec2_transit_gateway" "current" {
  filter {
    name   = "tag:Name"
    values = [var.transit_gateway_name]
  }
}

