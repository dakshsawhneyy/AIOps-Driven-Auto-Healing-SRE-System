########################
# Inference Lambda
########################

# Package the Lambda function code
data "archive_file" "inference" {
  type        = "zip"
  source_file = "${path.module}/lambda/inference.py"
  output_path = "${path.module}/lambda/inference.zip"
}

resource "aws_lambda_function" "inference" {
  filename         = data.archive_file.inference.output_path
  function_name    = "inferencer-${var.project_name}"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "inference.handler"
  source_code_hash = data.archive_file.inference.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      TARGET_BUCKET = aws_s3_bucket.bucket.bucket
    }
  }

  tags = local.common_tags
}