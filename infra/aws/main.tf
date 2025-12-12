############################
# CloudWatch Log Group
############################
resource "aws_cloudwatch_log_group" "aks_logs" {
  name              = "/aks/${var.project_name}"
  retention_in_days = 30
}


############################
# Kinesis Streams
############################
resource "aws_kinesis_stream" "fluentbit_metrics" {
  name        = "fluentbit-metrics"
  shard_count = 1
}
resource "aws_kinesis_stream" "normalizer_metrics" {
  name        = "normalizer_metrics"
  shard_count = 1
}


############################
# SNS Topic
############################
resource "aws_sns_topic" "sns-topic" {
  name = "aiops-topic"
}


############################
# DynamoDB Table
############################
resource "aws_dynamodb_table" "table" {
  name           = "aiops-incidents"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "incident_id"

  attribute {
    name = "incident_id"
    type = "S"
  }
}