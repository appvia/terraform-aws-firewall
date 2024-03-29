locals {
  ## Retreive the KMS key ARN
  kms_key_arn = var.create_kms_key ? aws_kms_key.current[0].arn : data.aws_kms_key.current[0].arn
}

## Provision a IAM policy document for the CloudWatch kms key 
data "aws_iam_policy_document" "logging" {
  # Allow cloud watch logs to use the key 
  statement {
    sid       = "AllowCloudWatchLogs"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }

  # Allow the account to use the key 
  statement {
    sid       = "AllowFullAccessToAccount"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}

## Provision a KMS key for the CloudWatch logs if required 
resource "aws_kms_key" "current" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for Inspection VPC CloudWatch logs in ${var.name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.logging.json
}

## Find the KMS key for CloudWatch logs if specified
data "aws_kms_key" "current" {
  count = var.cloudwatch_kms && !var.create_kms_key != "" ? 1 : 0

  key_id = var.cloudwatch_kms
}

## Provision the CloudWatch log group for the AWS Network Firewall service
resource "aws_cloudwatch_log_group" "logging" {
  name = "${var.name}-alert-log"

  kms_key_id        = var.cloudwatch_kms != "" ? local.kms_key_arn : null
  retention_in_days = var.cloudwatch_retention_in_days
  tags              = var.tags
}

