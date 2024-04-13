
## Provision the CloudWatch log group for the AWS Network Firewall alert-log
resource "aws_cloudwatch_log_group" "alert_log" {
  name = "${var.name}-alert-log"

  kms_key_id        = var.cloudwatch_kms != "" ? local.kms_key_arn : null
  retention_in_days = var.cloudwatch_retention_in_days
  tags              = var.tags
}

## Provision the CloudWatch log group for the AWS Network Firewall flow-log 
resource "aws_cloudwatch_log_group" "flow_log" {
  name = "${var.name}-flow-log"

  kms_key_id        = var.cloudwatch_kms != "" ? local.kms_key_arn : null
  retention_in_days = var.cloudwatch_retention_in_days
  tags              = var.tags
}

