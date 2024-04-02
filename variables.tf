variable "availability_zones" {
  description = "Number of availability zones to deploy into"
  type        = number

  validation {
    condition     = var.availability_zones > 0
    error_message = "Availability zones must be greater than 0"
  }
}

variable "enable_egress" {
  description = "Indicates the inspectio vpc should have egress enabled"
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the environment to deploy into"
  type        = string
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
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

  validation {
    condition     = var.cloudwatch_retention_in_days > 0
    error_message = "CloudWatch retention must be greater than 0"
  }
}

variable "transit_gateway_name" {
  description = "Name of the transit gateway"
  type        = string
  default     = "tgw"
}

variable "private_subnet_netmask" {
  description = "Netmask for the private subnets"
  type        = number
  default     = 24
}

variable "public_subnet_netmask" {
  description = "Netmask for the public subnets"
  type        = number
  default     = 24
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

variable "firewall_rules" {
  description = "A collection of firewall rules to add to the policy"
  type        = list(string)

  validation {
    condition     = length(var.firewall_rules) > 0
    error_message = "At least one firewall rule must be defined"
  }
}

variable "network_cidr_blocks" {
  description = "List of CIDR blocks defining the aws environment"
  type        = list(string)
  default     = ["10.0.0.0/8", "192.168.0.0/24"]

  validation {
    condition     = length(var.network_cidr_blocks) > 0
    error_message = "At least one network CIDR block must be defined"
  }
}

variable "stateful_capacity" {
  description = "The number of stateful rule groups to create"
  type        = number
  default     = 5000

  validation {
    condition     = var.stateful_capacity > 0
    error_message = "Stateful capacity must be greater than 0"
  }

  validation {
    condition     = var.stateful_capacity <= 30000
    error_message = "Stateful capacity must be less than or equal to 30000"
  }
}

variable "additional_rule_groups" {
  description = "A collection of additional rule groups to add to the policy"
  type = list(object({
    priority = number
    name     = string
  }))
  default = []
}

variable "policy_variables" {
  description = "A map of policy variables made available to the suricata rules"
  type        = map(list(string))
  default     = {}
}
