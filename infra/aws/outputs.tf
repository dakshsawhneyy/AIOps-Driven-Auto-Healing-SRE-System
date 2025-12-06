output "log_group_name" {
  value = aws_cloudwatch_log_group.aks_logs.name
}

output "kinesis_stream_name" {
  value = aws_kinesis_stream.fluentbit_metrics.name
}

output "fluentbit_role_arn" {
  value = aws_iam_role.fluentbit_role.arn
}


# IAM User Access Keys
output "fluentbit_access_key" {
  value = aws_iam_access_key.fluentbit.id
  sensitive = true
}
output "fluentbit_secret_key" {
  value = aws_iam_access_key.fluentbit.secret
  sensitive = true
}


