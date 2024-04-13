<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.11.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_inspection"></a> [inspection](#module\_inspection) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Number of availability zones to deploy into | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the environment to deploy into | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the Transit Gateway | `string` | n/a | yes |
| <a name="input_cloudwatch_kms"></a> [cloudwatch\_kms](#input\_cloudwatch\_kms) | Name of the KMS key to use for CloudWatch logs | `string` | `""` | no |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch\_retention\_in\_days](#input\_cloudwatch\_retention\_in\_days) | Number of days to retain CloudWatch logs | `number` | `30` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Create a KMS key for CloudWatch logs | `bool` | `false` | no |
| <a name="input_enable_dashboard"></a> [enable\_dashboard](#input\_enable\_dashboard) | Indicates we should deploy the CloudWatch Insights dashboard | `bool` | `false` | no |
| <a name="input_ip_prefixes"></a> [ip\_prefixes](#input\_ip\_prefixes) | A collection of ip sets which can be referenced by the rules | <pre>map(object({<br>    name           = string<br>    address_family = string<br>    max_entries    = number<br>    description    = string<br>    entries = list(object({<br>      cidr        = string<br>      description = string<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of principals to share the firewall policy with | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"100.64.0.0/21"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->