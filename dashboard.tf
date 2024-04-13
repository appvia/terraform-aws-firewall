
## Provisions the cloudwatch dashboard
resource "aws_cloudformation_stack" "dashboard" {
  count = var.enable_dashboard ? 1 : 0

  name          = format("LZA-NFW-%s-CloudWatch-Dashboard", title(var.name))
  capabilities  = ["CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND", "CAPABILITY_IAM"]
  on_failure    = "ROLLBACK"
  tags          = var.tags
  template_body = file("${path.module}/assets/cloudformation/nfw-cloudwatch-dashboard.yml")

  parameters = {
    ContributorInsightsRuleState = "ENABLED",
    FirewallAlertLogGroupName    = aws_cloudwatch_log_group.alert_log.name,
    FirewallFlowLogGroupName     = aws_cloudwatch_log_group.flow_log.name,
    FirewallName                 = var.name
    FirewallSubnetList           = values(local.private_subnet_id_by_az),
  }
}
