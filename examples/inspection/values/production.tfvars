
availability_zones = 3
create_kms_key     = false
name               = "inspection-prod"       # Name of the environment
transit_gateway_id = "tgw-0b1b2c3d4e5f6g7h8" # ID of the Transit Gateway
vpc_cidr           = "100.64.0.0/22"         # Using Carrier Grade NAT range

tags = {
  GitRepo     = "https://<CUSTOMER_ORG>/terraform-aws-firewall"
  Team        = "CloudPlatform"
  Project     = "CloudPlatform"
  Provisioner = "terraform"
}
