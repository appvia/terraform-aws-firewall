
#
## Note, the template for the dashboard is too big to be passed via the template_body parameter, so 
## we store it in an S3 bucket and pass the URL to the template_url parameter. 
#

## Create an S3 bucket allowing the account to access the bucket
data "aws_iam_policy_document" "dashboard" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [local.account_id]
    }

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.dashboard.arn,
      "${aws_s3_bucket.dashboard.arn}/*",
    ]
  }

  # allow cloudformation to access the bucket 
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudformation.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.dashboard.arn,
      "${aws_s3_bucket.dashboard.arn}/*",
    ]
  }
}

## Provision a bucket to store the cloudwatch dashboard template 
# tfsec:ignore:aws-s3-enable-bucket-encryption
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "dashboard" {
  bucket        = var.dashboard_bucket
  force_destroy = true
  tags          = var.tags
}

## Assign the bucket policy to the bucket 
resource "aws_s3_bucket_policy" "dashboard" {
  bucket = aws_s3_bucket.dashboard.bucket
  policy = data.aws_iam_policy_document.dashboard.json
}

## Ensure the bucket is not public 
resource "aws_s3_bucket_public_access_block" "dashboard" {
  bucket = aws_s3_bucket.dashboard.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## Ensure the bucket is private
resource "aws_s3_bucket_acl" "dashboard" {
  bucket = aws_s3_bucket.dashboard.bucket
  acl    = "private"
}

## Ensure encryption is enabled on the bucket 
# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "dashboard" {
  bucket = aws_s3_bucket.dashboard.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

## Ensure ownership is enabled on the bucket 
resource "aws_s3_bucket_ownership_controls" "dashboard" {
  bucket = aws_s3_bucket.dashboard.bucket

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

## Ensure versioning is enabled on the bucket 
resource "aws_s3_bucket_versioning" "dashboard" {
  bucket = aws_s3_bucket.dashboard.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

## Push the cloudwatch dashboard template to the bucket 
resource "aws_s3_object" "dashboard" {
  bucket                 = aws_s3_bucket.dashboard.bucket
  bucket_key_enabled     = true
  key                    = var.dashboard_key
  server_side_encryption = "AES256"
  source                 = "${path.module}/assets/cloudformation/nfw-cloudwatch-dashboard.yml"
  tags                   = var.tags
}

## Provisions the cloudwatch dashboard
resource "aws_cloudformation_stack" "dashboard" {
  count = var.enable_dashboard ? 1 : 0

  name         = format("LZA-NFW-%s-CloudWatch-Dashboard", title(var.name))
  capabilities = ["CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND", "CAPABILITY_IAM"]
  on_failure   = "ROLLBACK"
  tags         = var.tags
  template_url = local.dashboard_url

  parameters = {
    ContributorInsightsRuleState = "ENABLED",
    FirewallAlertLogGroupName    = aws_cloudwatch_log_group.alert_log.name,
    FirewallFlowLogGroupName     = aws_cloudwatch_log_group.flow_log.name,
    FirewallName                 = var.name
    FirewallSubnetList           = join(", ", values(local.private_subnet_id_by_az)),
  }

  depends_on = [
    aws_cloudwatch_log_group.alert_log,
    aws_cloudwatch_log_group.flow_log,
  ]
}
