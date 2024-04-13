variable "availability_zones" {
  description = "Number of availability zones to deploy into"
  type        = number
  default     = 3
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    GitRepo     = "https://github.com/appvia/terraform-aws-firewall"
    Team        = "CloudPlatform"
    Project     = "CloudPlatform"
    Provisioner = "terraform"
  }
}

variable "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  type        = string
}

variable "create_kms_key" {
  description = "Create a KMS key for CloudWatch logs"
  type        = bool
  default     = false
}

variable "ram_principals" {
  description = "A list of principals to share the firewall policy with"
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "Name of the environment to deploy into"
  type        = string
  default     = "inspection"
}

variable "enable_dashboard" {
  description = "Indicates we should deploy the CloudWatch Insights dashboard"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "100.64.0.0/21"
}

variable "private_subnet_netmask" {
  description = "Netmask for the private subnets"
  type        = number
  default     = 24
}
