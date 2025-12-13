########################
# Inference Lambda
########################

# Package the Lambda function code
# data "archive_file" "inference" {
#   type        = "zip"
#   source_file = "${path.module}/lambda/inference.py"
#   output_path = "${path.module}/lambda/inference.zip"
# }

resource "aws_lambda_function" "inference" {
  # filename         = data.archive_file.inference.output_path
  function_name    = "inferencer-${var.project_name}"
  role             = aws_iam_role.lambda_execution_role.arn
  # handler          = "inference.handler"
  # source_code_hash = data.archive_file.inference.output_base64sha256

  # runtime = "python3.12"

  package_type  = "Image"
  image_uri = "${local.ecr_repo_uri}"

  # layers = [
  #   aws_lambda_layer_version.inference_layer.arn
  # ]

  environment {
    variables = {
      MODEL_BUCKET = "aiopsplatform-data-bucket"
      INFERENCE_TABLE = local.dynamodb_table_arn
      SNS_TOPIC = local.sns_topic_arn
    }
  }

  tags = local.common_tags
}


# Connecting Layer with Lambda
# resource "aws_lambda_layer_version" "inference_layer" {
#   filename         = "${path.module}/layer.zip" # Path to your local zip file
#   layer_name       = "lambda_layer"
#   compatible_runtimes = ["python3.12"] # Specify compatible runtimes
#   source_code_hash = filebase64sha256("${path.module}/layer.zip") # Triggers updates when file changes
# }


# Connect the kinesis steam with this lambda function
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn = local.kinesis_stream_arn
  function_name = aws_lambda_function.inference.arn
  starting_position = "LATEST"    # Start processing new records only

  batch_size = 100
}