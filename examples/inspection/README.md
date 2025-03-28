<!-- BEGIN_TF_DOCS -->
## Providers

No providers.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the Transit Gateway | `string` | n/a | yes |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Number of availability zones to deploy into | `number` | `3` | no |
| <a name="input_cloudwatch_kms"></a> [cloudwatch\_kms](#input\_cloudwatch\_kms) | Name of the KMS key to use for CloudWatch logs | `string` | `""` | no |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch\_retention\_in\_days](#input\_cloudwatch\_retention\_in\_days) | Number of days to retain CloudWatch logs | `number` | `30` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Create a KMS key for CloudWatch logs | `bool` | `false` | no |
| <a name="input_enable_dashboard"></a> [enable\_dashboard](#input\_enable\_dashboard) | Indicates we should deploy the CloudWatch Insights dashboard | `bool` | `false` | no |
| <a name="input_ip_prefixes"></a> [ip\_prefixes](#input\_ip\_prefixes) | A collection of ip sets which can be referenced by the rules | <pre>map(object({<br/>    name           = string<br/>    address_family = string<br/>    max_entries    = number<br/>    description    = string<br/>    entries = list(object({<br/>      cidr        = string<br/>      description = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the environment to deploy into | `string` | `"inspection"` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of principals to share the firewall policy with | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | <pre>{<br/>  "GitRepo": "https://github.com/appvia/terraform-aws-firewall",<br/>  "Project": "CloudPlatform",<br/>  "Provisioner": "terraform",<br/>  "Team": "CloudPlatform"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"100.64.0.0/21"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall_rule_groups"></a> [firewall\_rule\_groups](#output\_firewall\_rule\_groups) | The rule groups to associate with the firewall. |
| <a name="output_policy_variables"></a> [policy\_variables](#output\_policy\_variables) | The policy variables to associate with the firewall. |
| <a name="output_private_subnet_id_by_az"></a> [private\_subnet\_id\_by\_az](#output\_private\_subnet\_id\_by\_az) | The private subnet IDs by availability zone. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | The IDs of the private subnets. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | The IDs of the public subnets. |
| <a name="output_ram_principals"></a> [ram\_principals](#output\_ram\_principals) | The principals to share the firewall with. |
| <a name="output_routing_configuration"></a> [routing\_configuration](#output\_routing\_configuration) | The routing configuration. |
| <a name="output_transit_attachment_id"></a> [transit\_attachment\_id](#output\_transit\_attachment\_id) | The ID of the transit gateway attachment. |
| <a name="output_transit_route_table_by_az"></a> [transit\_route\_table\_by\_az](#output\_transit\_route\_table\_by\_az) | The transit route table by availability zone. |
| <a name="output_transit_subnet_ids"></a> [transit\_subnet\_ids](#output\_transit\_subnet\_ids) | The IDs of the transit subnets. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC. |
<!-- END_TF_DOCS -->