############################
# CloudWatch Log Group
############################
resource "aws_cloudwatch_log_group" "aks_logs" {
  name              = "/aks/${var.project_name}"
  retention_in_days = 30
}


############################
# Kinesis Stream
############################
resource "aws_kinesis_stream" "fluentbit_metrics" {
  name        = "fluentbit-metrics"
  shard_count = 1
}

