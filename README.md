![Github Actions](../../actions/workflows/terraform.yml/badge.svg)

# Terraform AWS Inspection VPC

<em>Note: the following is purely for illustrative purposes</em>

<img src="docs/inspection.png"></img>

This repository manages the inspection vpc and rulesets within the AWS estate. The inspection VPC is seated at the heart of the estate, and leverages [AWS Network Firewall](https://aws.amazon.com/network-firewall/) as a managed solution. It's remit is

- To filter all traffic between networks and enviroments (i.e. production, development, ci).
- To filter all egress traffic from the spokes to the outbound internet.
- To provide the spokes with a central place to egress all traffic to the internet i.e. sharing NAT gateways.

## Rule Group Variables

A firewall policy in AWS Network firewall comprises of one of more references stateful / stateless [rule groups](https://docs.aws.amazon.com/network-firewall/latest/developerguide/rule-groups.html). The difference between these two groups is similar to NACL vs security groups in AWS; where SG's have knowlegde of direction and permit established connections to return traffic without the need of an additional rule. Note this module follows AWS recommendations, and has opted to ignore stateless rules completely, deferring purely to stateful Suricata rules.

[Rule groups](https://docs.aws.amazon.com/network-firewall/latest/developerguide/rule-groups.html) also have the ability to source in variables containing ipsets (a collection of CIDR block) or portsets (a collection of ports). These be referenced within the Suricata rules themselves, providing a reusable snippet i.e.

```shell
(in the tfvars)
policy_variables = {
  devops_net = ["10.128.0.0/24"]
  remote_net = ["10.230.0.0/24"]
}

# This will produce variables DEVOPS_NET and REMOTE_NET, and make
# them available in the ruleset

pass  tcp $REMOTE_NET any -> $HOME_NET
or
pass  tcp [!$REMOTE_NET, $DEVOPS_NET] any -> $HOME_NET
```

The module use the contents of the `var.firewall_rules` to source in the files and merge them together to produce the final ruleset.

## Event Logging

Currently the inspection VPC is setup to segregate the flow and alert logs into two CloudWatch log groups:

- Alerts: are directed to `${var.name}-alert-log`.
- Flows: are directed to `${var.name}-flow-log`.

This module also supports the ability to encrypt the logs using a KMS key. If the `var.create_kms_key` is set to true, a KMS key will be created and used to encrypt the logs. The key will be created in the same region as the logs.

## CloudWatch Dashboard

The module also supports the ability to deploy a CloudWatch dashboard to visualise the logs. The dashboard is created using a CloudFormation template, and is deployed into the same region as the logs. The dashboard is created using the `aws_cloudformation_stack` resource, and is created using the [assets/cloudfomation/nfw-cloudwatch-dashboard](assets/cloudfomation/nfw-cloudwatch-dashboard.yml) template.

## Pipeline Permissions

The following pipeline permissions are required to deploy the inspection VPC

```hcl
# tfsec:ignore:aws-iam-no-policy-wildcards
module "network_inspection_vpc_admin" {
  count   = var.repositories.firewall != null ? 1 : 0
  source  = "appvia/oidc/aws//modules/role"
  version = "1.2.0"

  name                = var.repositories.firewall.role_name
  common_provider     = var.scm_name
  description         = "Deployment role used to deploy the inspection vpc"
  permission_boundary = var.default_permissions_boundary_name
  repository          = var.repositories.firewall.url
  tags                = var.tags

  read_only_policy_arns = [
    "arn:aws:iam::aws:policy/AWSResourceAccessManagerReadOnlyAccess",
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]
  read_write_policy_arns = [
    "arn:aws:iam::aws:policy/AWSResourceAccessManagerFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/CloudFormationFullAccess", # Assuming you are deploying the dashboard
    "arn:aws:iam::aws:policy/LambdaFullAccess",
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/job-function/NetworkAdministrator",
  ]

  read_write_inline_policies = {
    "additional" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "network-firewall:Associate*",
            "network-firewall:Create*",
            "network-firewall:Delete*",
            "network-firewall:Describe*",
            "network-firewall:Disassociate*",
            "network-firewall:List*",
            "network-firewall:Put*",
            "network-firewall:Tag*",
            "network-firewall:Untag*",
            "network-firewall:Update*",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = ["iam:CreateServiceLinkedRole"],
          Effect   = "Allow",
          Resource = ["arn:aws:iam::*:role/aws-service-role/network-firewall.amazonaws.com/AWSServiceRoleForNetworkFirewall"]
        },
        {
          Action   = ["logs:*"],
          Effect   = "Allow",
          Resource = ["*"]
        }
      ]


      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "network-firewall:Describe*",
            "network-firewall:List*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "logs:Get*",
            "logs:List*",
            "logs:Describe*",
          ],
          Effect   = "Allow",
          Resource = ["*"]
        }
      ]
    })
  }

  read_only_inline_policies = {
    "additional" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "network-firewall:Describe*",
            "network-firewall:List*"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "logs:Describe*",
            "logs:Get*",
            "logs:List*",
          ],
          Effect   = "Allow",
          Resource = ["*"]
        }
      ]
    })
  }


```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_network_firewall"></a> [network\_firewall](#module\_network\_firewall) | aws-ia/networkfirewall/aws | 1.0.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | appvia/network/aws | 0.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack.dashboard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |
| [aws_cloudwatch_log_group.alert_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.flow_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ec2_managed_prefix_list.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list) | resource |
| [aws_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_networkfirewall_firewall_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_rule_group.stateful](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_ram_principal_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | resource |
| [aws_ram_resource_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | resource |
| [aws_ram_resource_share.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_transit_gateway.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway) | data source |
| [aws_iam_policy_document.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Number of availability zones to deploy into | `number` | n/a | yes |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | A collection of firewall rules to add to the policy | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the environment to deploy into | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy into | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_additional_rule_groups"></a> [additional\_rule\_groups](#input\_additional\_rule\_groups) | A collection of additional rule groups to add to the policy | <pre>list(object({<br>    priority = number<br>    name     = string<br>  }))</pre> | `[]` | no |
| <a name="input_cloudwatch_kms"></a> [cloudwatch\_kms](#input\_cloudwatch\_kms) | Name of the KMS key to use for CloudWatch logs | `string` | `""` | no |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch\_retention\_in\_days](#input\_cloudwatch\_retention\_in\_days) | Number of days to retain CloudWatch logs | `number` | `30` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Create a KMS key for CloudWatch logs | `bool` | `false` | no |
| <a name="input_enable_dashboard"></a> [enable\_dashboard](#input\_enable\_dashboard) | Indicates we should deploy the CloudWatch Insights dashboard | `bool` | `false` | no |
| <a name="input_enable_egress"></a> [enable\_egress](#input\_enable\_egress) | Indicates the inspectio vpc should have egress enabled | `bool` | `false` | no |
| <a name="input_enable_policy_change_protection"></a> [enable\_policy\_change\_protection](#input\_enable\_policy\_change\_protection) | Indicates the firewall policy should be protected from changes | `bool` | `false` | no |
| <a name="input_enable_subnet_change_protection"></a> [enable\_subnet\_change\_protection](#input\_enable\_subnet\_change\_protection) | Indicates the firewall subnets should be protected from changes | `bool` | `false` | no |
| <a name="input_ip_prefixes"></a> [ip\_prefixes](#input\_ip\_prefixes) | A collection of ip sets which can be referenced by the rules | <pre>map(object({<br>    name           = string<br>    address_family = string<br>    max_entries    = number<br>    description    = string<br>    entries = list(object({<br>      cidr        = string<br>      description = string<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_network_cidr_blocks"></a> [network\_cidr\_blocks](#input\_network\_cidr\_blocks) | List of CIDR blocks defining the aws environment | `list(string)` | <pre>[<br>  "10.0.0.0/8",<br>  "192.168.0.0/24"<br>]</pre> | no |
| <a name="input_policy_variables"></a> [policy\_variables](#input\_policy\_variables) | A map of policy variables made available to the suricata rules | `map(list(string))` | `{}` | no |
| <a name="input_private_subnet_netmask"></a> [private\_subnet\_netmask](#input\_private\_subnet\_netmask) | Netmask for the private subnets | `number` | `24` | no |
| <a name="input_public_subnet_netmask"></a> [public\_subnet\_netmask](#input\_public\_subnet\_netmask) | Netmask for the public subnets | `number` | `24` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of principals to share the firewall policy with | `map(string)` | `{}` | no |
| <a name="input_stateful_capacity"></a> [stateful\_capacity](#input\_stateful\_capacity) | The number of stateful rule groups to create | `number` | `5000` | no |
| <a name="input_transit_gateway_name"></a> [transit\_gateway\_name](#input\_transit\_gateway\_name) | Name of the transit gateway | `string` | `"tgw"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"100.64.0.0/21"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall_arn"></a> [firewall\_arn](#output\_firewall\_arn) | The ARN of the firewall |
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | The ARN of the firewall. |
| <a name="output_firewall_rule_groups"></a> [firewall\_rule\_groups](#output\_firewall\_rule\_groups) | The rule groups to associate with the firewall. |
| <a name="output_policy_variables"></a> [policy\_variables](#output\_policy\_variables) | The policy variables to associate with the firewall. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | The IDs of the private subnets. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | The IDs of the public subnets. |
| <a name="output_ram_principals"></a> [ram\_principals](#output\_ram\_principals) | The principals to share the firewall with. |
| <a name="output_stateful_rule_group_id"></a> [stateful\_rule\_group\_id](#output\_stateful\_rule\_group\_id) | The ID of the stateful rule group. |
| <a name="output_transit_attachment_id"></a> [transit\_attachment\_id](#output\_transit\_attachment\_id) | The ID of the transit gateway attachment. |
| <a name="output_transit_subnet_ids"></a> [transit\_subnet\_ids](#output\_transit\_subnet\_ids) | The IDs of the transit subnets. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC. |
<!-- END_TF_DOCS -->
