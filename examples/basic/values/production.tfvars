
availability_zones   = 3
cloudwatch_kms       = "alias/inspection/logging"
create_kms_key       = false
name                 = "inspection-prod" # Name of the environment
region               = "eu-west-2"       # AWS region
stateful_capacity    = 5000              # Stateful capacity units
transit_gateway_name = "tgw"             # Name of the transit gateway to attach to
vpc_cidr             = "100.64.0.0/22"   # Using Carrier Grade NAT range

# Variables made available to the suricata rules engine
policy_variables = {
  devops_net                = ["10.128.0.0/22"]
  remote_net                = ["10.128.4.0/24"]
  sandbox_net               = ["10.129.64.0/18"]
  private_vpc_endpoints_net = ["10.128.8.0/24"]
  databricks_net            = ["10.128.160.0/20"]
}

firewall_rules = [
  "rules/inspection-prod.rules"
]

# Collection of tags applied to all resources
tags = {
  GitRepo     = "https://<CUSTOMER_ORG>/terraform-aws-firewall"
  Team        = "CloudPlatform"
  Project     = "CloudPlatform"
  Provisioner = "terraform"
}
