<!-- markdownlint-disable -->

<a href="https://www.appvia.io/"><img src="https://github.com/appvia/terraform-aws-firewall/blob/main/appvia_banner.jpg?raw=true" alt="Appvia Banner"/></a><br/><p align="right"> <a href="https://registry.terraform.io/modules/appvia/firewall/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-firewall/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-firewall.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-firewall/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-firewall.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](https://github.com/appvia/terraform-aws-firewall/actions/workflows/terraform.yml/badge.svg)

# Terraform AWS Inspection VPC

<em>Note: the following is purely for illustrative purposes</em>

<p align="center">
  <img src="https://github.com/appvia/terraform-aws-firewall/blob/main/docs/inspection.png?raw=true">
</p>

This repository manages the inspection VPC and rulesets within the AWS estate. The inspection VPC is seated at the heart of the estate, and leverages [AWS Network Firewall](https://aws.amazon.com/network-firewall/) as a managed solution. Its remit is:

- To filter all traffic between networks and environments (i.e. production, development, ci).
- To filter all egress traffic from the spokes to the outbound internet.
- To provide the spokes with a central place to egress all traffic to the internet i.e. sharing NAT gateways.

## Key Features

- **AWS Network Firewall Integration**: Leverages AWS managed Network Firewall for stateful packet inspection
- **Suricata Rule Support**: Supports custom Suricata rules for advanced threat detection
- **Policy Variables**: Dynamic rule configuration using policy variables and IP sets
- **IP Prefix Management**: Managed prefix lists for efficient IP address management
- **External Rule Groups**: Support for AWS managed and custom external rule groups
- **Egress Support**: Optional egress traffic routing through the inspection VPC
- **CloudWatch Integration**: Comprehensive logging and monitoring with optional dashboard
- **KMS Encryption**: Optional encryption for CloudWatch logs using KMS
- **RAM Sharing**: Share firewall policies across AWS accounts and organizations
- **VPC Reuse**: Deploy into existing VPCs or create new ones
- **Protection Features**: Optional protection against accidental changes

## Rule Group Variables

A firewall policy in AWS Network Firewall comprises one or more references to stateful / stateless [rule groups](https://docs.aws.amazon.com/network-firewall/latest/developerguide/rule-groups.html). The difference between these two groups is similar to NACL vs security groups in AWS; where security groups have knowledge of direction and permit established connections to return traffic without the need of an additional rule. Note this module follows AWS recommendations, and has opted to ignore stateless rules completely, deferring purely to stateful Suricata rules.

[Rule groups](https://docs.aws.amazon.com/network-firewall/latest/developerguide/rule-groups.html) also have the ability to source in variables containing ipsets (a collection of CIDR blocks) or portsets (a collection of ports). These can be referenced within the Suricata rules themselves, providing a reusable snippet i.e.

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

The module uses the contents of the `var.firewall_rules` to source in the files and merge them together to produce the final ruleset.

## IP Prefixes

The module supports the creation of managed prefix lists that can be referenced in Suricata rules. This is useful for managing large sets of IP addresses that need to be referenced in multiple rules.

```hcl
ip_prefixes = {
  "blocked_ips" = {
    name           = "blocked-ips"
    address_family = "IPv4"
    max_entries    = 1000
    description    = "List of blocked IP addresses"
    entries = [
      {
        cidr        = "192.168.1.0/24"
        description = "Internal blocked range"
      },
      {
        cidr        = "10.0.0.0/8"
        description = "Another blocked range"
      }
    ]
  }
}
```

These prefix lists can then be referenced in Suricata rules using the `$BLOCKED_IPS` variable.

## External Rule Groups

The module supports referencing external rule groups that have been created outside of this module. This is useful for sharing rule groups across multiple firewall deployments or using AWS managed rule groups.

```hcl
external_rule_groups = [
  {
    priority = 100
    arn      = "arn:aws:network-firewall:us-west-2:111122223333:stateful-rulegroup/domains"
  }
]
```

When using external rule groups, the module will not create its own stateful rule group and will instead use the provided external rule groups.

## Egress Support

The inspection VPC can be configured to support egress traffic. This is useful when the inspection VPC is used as a central point for all egress traffic from the spokes. The egress support is enabled by setting the `var.enable_egress` to true. When enabled, the inspection VPC will have a route table that routes all traffic to the internet gateway. The route table is associated with the private subnets, and the internet gateway is attached to the VPC.

To enable egress support,

- `var.enable_egress` must be set to true.
- `var.public_subnet_netmask` must be set to a non-zero value.

```hcl
## Provision a inspection firewall, but with an existing vpc
module "inspection" {
  source = "../.."

  availability_zones     = var.availability_zones
  firewall_rules         = local.firewall_rules
  name                   = var.name
  private_subnet_netmask = var.private_subnet_netmask
  public_subnet_netmask  = var.public_subnet_netmask
  ram_principals         = var.ram_principals
  tags                   = var.tags
  transit_gateway_id     = var.transit_gateway_id
}
```

## Event Logging

Currently the inspection VPC is setup to segregate the flow and alert logs into two CloudWatch log groups:

- Alerts: are directed to `${var.name}-alert-log`.
- Flows: are directed to `${var.name}-flow-log`.

This module also supports the ability to encrypt the logs using a KMS key. If the `var.create_kms_key` is set to true, a KMS key will be created and used to encrypt the logs. The key will be created in the same region as the logs.

Alternatively, you can specify an existing KMS key using the `var.cloudwatch_kms` variable. This is useful when you want to use a centralized KMS key for all your CloudWatch logs.

```hcl
module "inspection" {
  source = "../.."

  # ... other variables ...
  
  # Option 1: Create a new KMS key
  create_kms_key = true
  
  # Option 2: Use an existing KMS key
  cloudwatch_kms = "alias/my-existing-key"
}
```

## CloudWatch Dashboard

The module also supports the ability to deploy a CloudWatch dashboard to visualise the logs. The dashboard is created using a CloudFormation template, and is deployed into the same region as the logs. The dashboard is created using the `aws_cloudformation_stack` resource, and is created using the [assets/cloudformation/nfw-cloudwatch-dashboard](assets/cloudformation/nfw-cloudwatch-dashboard.yml) template.

To enable the dashboard, set `var.enable_dashboard` to true:

```hcl
module "inspection" {
  source = "../.."

  # ... other variables ...
  
  enable_dashboard = true
}
```

The dashboard provides comprehensive monitoring of your Network Firewall including:

- Firewall metrics and performance
- Flow and alert log analysis
- Contributor insights for security monitoring
- Custom widgets for traffic analysis

## RAM Sharing

The module supports sharing the firewall policy with other AWS accounts using AWS Resource Access Manager (RAM). This is useful when you want to share the same firewall policy across multiple accounts or organizations.

```hcl
module "inspection" {
  source = "../.."

  # ... other variables ...
  
  ram_principals = {
    "account-1" = "123456789012"
    "account-2" = "987654321098"
  }
}
```

The shared firewall policy can then be used by other accounts to create their own Network Firewall instances with the same rules.

## Firewall Protection

The module supports enabling protection against accidental changes to the firewall policy and subnets:

```hcl
module "inspection" {
  source = "../.."

  # ... other variables ...
  
  # Protect against policy changes
  enable_policy_change_protection = true
  
  # Protect against subnet changes
  enable_subnet_change_protection = true
}
```

When enabled, these protections prevent accidental modifications that could disrupt network traffic.

## Stateful Rule Capacity

The module allows you to configure the capacity for stateful rule groups. The default capacity is 5000 rules, but this can be adjusted based on your needs:

```hcl
module "inspection" {
  source = "../.."

  # ... other variables ...
  
  # Increase capacity for more complex rule sets
  stateful_capacity = 10000
}
```

The maximum capacity is 30,000 rules per stateful rule group.

## Reusing an Existing VPC

<p align="center">
  <img src="https://github.com/appvia/terraform-aws-firewall/blob/main/docs/egress.jpg?raw=true">
</p>

The module supports the ability to reuse an existing VPC. This is useful when the inspection VPC is being deployed into an existing environment. The options defined depend on whether egress is enabled or not.

To reuse an existing VPC, **with egress support**

- `var.vpc_id` must be set to the ID of the VPC.
- `var.private_subnet_id_by_az` must be set to a map of availability zone to subnet id i.e `{ "eu-west-1a" = "subnet-12345678" }`.
- `var.public_route_table_ids` must be set to a list of public route table ids associated with the public subnets.
- `var.transit_route_table_by_az` must be set to a map of availability zone to transit route table id i.e `{ "eu-west-1a" = "rtb-12345678" }`.
- `var.transit_route_table_ids` must be set to a list of transit route table ids associated with the transit subnets.

```hcl
## Provision a inspection firewall, but with an existing vpc
module "inspection" {
  source = "../.."

  availability_zones        = var.availability_zones
  firewall_rules            = local.firewall_rules
  name                      = var.name
  private_subnet_id_by_az   = var.private_subnet_id_by_az
  public_route_table_ids    = var.public_route_table_ids
  ram_principals            = var.ram_principals
  tags                      = var.tags
  transit_gateway_id        = var.transit_gateway_id
  transit_route_table_by_az = var.transit_route_table_by_az
  transit_route_table_ids   = var.transit_route_table_ids
  vpc_id                    = var.vpc_id
}
```

To reuse an existing VPC, **without egress support**

- `var.vpc_id` must be set to the ID of the VPC.
- `var.private_subnet_id_by_az` must be set to a map of availability zone to subnet id i.e `{ "eu-west-1a" = "subnet-12345678" }`.
- `var.transit_route_table_by_az` must be set to a map of availability zone to transit route table id i.e `{ "eu-west-1a" = "rtb-12345678" }`.

```hcl
module "inspection" {
  source = "../.."

  availability_zones        = var.availability_zones
  create_kms_key            = false
  enable_dashboard          = var.enable_dashboard
  firewall_rules            = local.firewall_rules
  name                      = var.name
  private_subnet_id_by_az   = var.vpc.private_subnet_id_by_az
  ram_principals            = var.ram_principals
  tags                      = var.tags
  transit_gateway_id        = var.transit_gateway_id
  transit_route_table_by_az = var.vpc.transit_route_table_by_az
  vpc_id                    = var.vpc.vpc_id
}
```

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

## IAM Permissions

The following permissions are required to deploy the inspection firewall. The module requires permissions for Network Firewall, VPC management, CloudWatch Logs, KMS (if using encryption), and RAM (if sharing resources).

### Required AWS Managed Policies

- `AWSResourceAccessManagerFullAccess` (for RAM sharing)
- `AmazonEC2FullAccess` (for VPC and Network Firewall resources)
- `CloudWatchLogsFullAccess` (for log group management)
- `CloudFormationFullAccess` (if deploying the dashboard)
- `ReadOnlyAccess` (for resource discovery)

### Required Inline Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "network-firewall:Associate*",
        "network-firewall:Create*",
        "network-firewall:Delete*",
        "network-firewall:Describe*",
        "network-firewall:Disassociate*",
        "network-firewall:List*",
        "network-firewall:Put*",
        "network-firewall:Tag*",
        "network-firewall:Untag*",
        "network-firewall:Update*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": ["iam:CreateServiceLinkedRole"],
      "Effect": "Allow",
      "Resource": ["arn:aws:iam::*:role/aws-service-role/network-firewall.amazonaws.com/AWSServiceRoleForNetworkFirewall"]
    },
    {
      "Action": ["logs:*"],
      "Effect": "Allow",
      "Resource": ["*"]
    }
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.4 |

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
| <a name="input_dashboard_bucket"></a> [dashboard\_bucket](#input\_dashboard\_bucket) | The name of the S3 bucket to store the CloudWatch Insights dashboard | `string` | `"lza-inspection-cw-dashboard"` | no |
| <a name="input_dashboard_key"></a> [dashboard\_key](#input\_dashboard\_key) | The name of the S3 bucket key to store the CloudWatch Insights dashboard | `string` | `"nfw-cloudwatch-dashboard.yml"` | no |
| <a name="input_enable_dashboard"></a> [enable\_dashboard](#input\_enable\_dashboard) | Indicates we should deploy the CloudWatch Insights dashboard | `bool` | `false` | no |
| <a name="input_enable_egress"></a> [enable\_egress](#input\_enable\_egress) | Indicates the inspectio vpc should have egress enabled | `bool` | `false` | no |
| <a name="input_enable_policy_change_protection"></a> [enable\_policy\_change\_protection](#input\_enable\_policy\_change\_protection) | Indicates the firewall policy should be protected from changes | `bool` | `false` | no |
| <a name="input_enable_subnet_change_protection"></a> [enable\_subnet\_change\_protection](#input\_enable\_subnet\_change\_protection) | Indicates the firewall subnets should be protected from changes | `bool` | `false` | no |
| <a name="input_external_rule_groups"></a> [external\_rule\_groups](#input\_external\_rule\_groups) | A collection of additional rule groups to add to the policy | <pre>list(object({<br/>    priority = number<br/>    arn      = string<br/>  }))</pre> | `null` | no |
| <a name="input_firewall_rules"></a> [firewall\_rules](#input\_firewall\_rules) | A collection of firewall rules to add to the policy | <pre>list(object({<br/>    name    = string<br/>    content = string<br/>  }))</pre> | `null` | no |
| <a name="input_ip_prefixes"></a> [ip\_prefixes](#input\_ip\_prefixes) | A collection of ip sets which can be referenced by the rules | <pre>map(object({<br/>    name           = string<br/>    address_family = string<br/>    max_entries    = number<br/>    description    = string<br/>    entries = list(object({<br/>      cidr        = string<br/>      description = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_network_cidr_blocks"></a> [network\_cidr\_blocks](#input\_network\_cidr\_blocks) | List of CIDR blocks defining the aws environment | `list(string)` | <pre>[<br/>  "10.0.0.0/8",<br/>  "192.168.0.0/24"<br/>]</pre> | no |
| <a name="input_policy_variables"></a> [policy\_variables](#input\_policy\_variables) | A map of policy variables made available to the suricata rules | `map(list(string))` | `{}` | no |
| <a name="input_private_subnet_id_by_az"></a> [private\_subnet\_id\_by\_az](#input\_private\_subnet\_id\_by\_az) | If reusing an existing VPC, provider a map of az to subnet id | `map(string)` | `{}` | no |
| <a name="input_private_subnet_netmask"></a> [private\_subnet\_netmask](#input\_private\_subnet\_netmask) | Netmask for the private subnets | `number` | `24` | no |
| <a name="input_public_route_table_ids"></a> [public\_route\_table\_ids](#input\_public\_route\_table\_ids) | If reusing an existing VPC, provide the public route table ids | `list(string)` | `[]` | no |
| <a name="input_public_subnet_netmask"></a> [public\_subnet\_netmask](#input\_public\_subnet\_netmask) | Netmask for the public subnets | `number` | `0` | no |
| <a name="input_ram_principals"></a> [ram\_principals](#input\_ram\_principals) | A list of principals to share the firewall policy with | `map(string)` | `{}` | no |
| <a name="input_stateful_capacity"></a> [stateful\_capacity](#input\_stateful\_capacity) | The number of stateful rule groups to create | `number` | `5000` | no |
| <a name="input_transit_route_table_by_az"></a> [transit\_route\_table\_by\_az](#input\_transit\_route\_table\_by\_az) | If reusing an existing VPC, provider a map of az to subnet id | `map(string)` | `{}` | no |
| <a name="input_transit_route_table_ids"></a> [transit\_route\_table\_ids](#input\_transit\_route\_table\_ids) | If reusing an existing VPC, provide the transit route table ids | `list(string)` | `[]` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"100.64.0.0/21"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | If reusing an existing VPC, provide the VPC ID and private subnets ids | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | The ARN of the firewall. |
| <a name="output_firewall_rule_groups"></a> [firewall\_rule\_groups](#output\_firewall\_rule\_groups) | The rule groups to associate with the firewall. |
| <a name="output_policy_variables"></a> [policy\_variables](#output\_policy\_variables) | The policy variables to associate with the firewall. |
| <a name="output_private_subnet_id_by_az"></a> [private\_subnet\_id\_by\_az](#output\_private\_subnet\_id\_by\_az) | The private subnet IDs by availability zone. |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | The IDs of the private subnets. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | The IDs of the public subnets. |
| <a name="output_ram_principals"></a> [ram\_principals](#output\_ram\_principals) | The principals to share the firewall with. |
| <a name="output_routing_configuration"></a> [routing\_configuration](#output\_routing\_configuration) | The routing configuration for the firewall. |
| <a name="output_transit_attachment_id"></a> [transit\_attachment\_id](#output\_transit\_attachment\_id) | The ID of the transit gateway attachment. |
| <a name="output_transit_route_table_by_az"></a> [transit\_route\_table\_by\_az](#output\_transit\_route\_table\_by\_az) | The transit route table by availability zone. |
| <a name="output_transit_subnet_ids"></a> [transit\_subnet\_ids](#output\_transit\_subnet\_ids) | The IDs of the transit subnets. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC. |
<!-- END_TF_DOCS -->
