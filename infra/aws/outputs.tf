output "log_group_name" {
  value = aws_cloudwatch_log_group.aks_logs.name
}

output "kinesis_stream_name" {
  value = aws_kinesis_stream.fluentbit_metrics.name
}

output "kinesis_stream_arn" {
  value = aws_kinesis_stream.fluentbit_metrics.arn
}

output "normalizer_kinesis_stream_name" {
  value = aws_kinesis_stream.normalizer_metrics.name
}

output "normalizer_kinesis_stream_arn" {
  value = aws_kinesis_stream.normalizer_metrics.arn
}

# IAM User Access Keys
output "fluentbit_access_key" {
  value = aws_iam_access_key.fluentbit_keys.id
  sensitive = true
}
output "fluentbit_secret_key" {
  value = aws_iam_access_key.fluentbit_keys.secret
  sensitive = true
}


output "sns_topic_name" {
  value = aws_sns_topic.sns-topic.name
}
output "sns_topic_arn" {
  value = aws_sns_topic.sns-topic.arn
}


output "dynamodb_table_name" {
  value = aws_dynamodb_table.table.name
}
output "dynamodb_table_arn" {
  value = aws_dynamodb_table.table.arn
}