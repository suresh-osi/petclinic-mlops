output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "newrelic_cloudwatch_role_arn" {
  description = "ARN of the NewRelic CloudWatch integration role"
  value       = aws_iam_role.newrelic_cloudwatch_role.arn
}

output "newrelic_cloudwatch_role_name" {
  description = "Name of the NewRelic CloudWatch integration role"
  value       = aws_iam_role.newrelic_cloudwatch_role.name
}

output "aws_account_id" {
  description = "AWS Account ID for NewRelic integration"
  value       = data.aws_caller_identity.current.account_id
}

output "newrelic_log_forwarder_arn" {
  description = "ARN of the NewRelic log forwarder Lambda"
  value       = aws_lambda_function.newrelic_log_forwarder.arn
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups forwarding to NewRelic"
  value = [
    aws_cloudwatch_log_group.petclinic_app.name,
    aws_cloudwatch_log_group.petclinic_apache_access.name,
    aws_cloudwatch_log_group.petclinic_apache_error.name,
    aws_cloudwatch_log_group.petclinic_userdata.name,
  ]
}
