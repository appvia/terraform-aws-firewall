
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  type        = string
}

variable "ram_principals" {
  description = "A list of principals to share the firewall policy with"
  type        = map(string)
  default     = {}
}
