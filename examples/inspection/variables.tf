variable "availability_zones" {
  description = "Number of availability zones to deploy into"
  type        = number
  default     = 3
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

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    GitRepo     = "https://github.com/appvia/terraform-aws-firewall"
    Team        = "CloudPlatform"
    Project     = "CloudPlatform"
    Provisioner = "terraform"
  }
}

variable "create_kms_key" {
  description = "Create a KMS key for CloudWatch logs"
  type        = bool
  default     = false
}

variable "cloudwatch_kms" {
  description = "Name of the KMS key to use for CloudWatch logs"
  type        = string
  default     = ""
}

variable "cloudwatch_retention_in_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "100.64.0.0/21"
}

variable "ram_principals" {
  description = "A list of principals to share the firewall policy with"
  type        = map(string)
  default     = {}
}

variable "ip_prefixes" {
  description = "A collection of ip sets which can be referenced by the rules"
  type = map(object({
    name           = string
    address_family = string
    max_entries    = number
    description    = string
    entries = list(object({
      cidr        = string
      description = string
    }))
  }))
  default = {}
}
