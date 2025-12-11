########################
# chaos_labeler Lambda
########################

# Package the Lambda function code
data "archive_file" "chaos_labeler" {
  type        = "zip"
  source_file = "${path.module}/lambda/chaos_labeler.py"
  output_path = "${path.module}/lambda/chaos_labeler.zip"
}

resource "aws_lambda_function" "chaos_labeler" {
  filename         = data.archive_file.chaos_labeler.output_path
  function_name    = "chaos_labeler-${var.project_name}"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "chaos_labeler.handler"
  source_code_hash = data.archive_file.chaos_labeler.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      TARGET_BUCKET = "aiopsplatform-data-bucket"
    }
  }

  tags = local.common_tags
}