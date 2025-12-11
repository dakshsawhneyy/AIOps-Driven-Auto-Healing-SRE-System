#########################
# Bucket for storing data
#########################
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  #force_destroy = false

  # lifecycle {
  #   prevent_destroy = true
  # }

  # aws s3 rm s3://aiopsplatform-data-bucket --recursive ## Delete bucket
  # terraform state rm aws_s3_bucket.bucket
}

########################
# Normalization Lambda
########################

# Package the Lambda function code
data "archive_file" "normalizer" {
  type        = "zip"
  source_file = "${path.module}/lambda/normalizer.py"
  output_path = "${path.module}/lambda/normalizer.zip"
}

resource "aws_lambda_function" "normalizer" {
  filename         = data.archive_file.normalizer.output_path
  function_name    = "normalizer-${var.project_name}"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "normalizer.handler"
  source_code_hash = data.archive_file.normalizer.output_base64sha256

  timeout = 400
  runtime = "python3.12"

  environment {
    variables = {
      TARGET_BUCKET = aws_s3_bucket.bucket.bucket
    }
  }

  tags = local.common_tags
}

# Connect the kinesis steam with this lambda function
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn = local.kinesis_stream_arn
  function_name = aws_lambda_function.normalizer.arn
  starting_position = "LATEST"    # Start processing new records only

  batch_size = 100
}