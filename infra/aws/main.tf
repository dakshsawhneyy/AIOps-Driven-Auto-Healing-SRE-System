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