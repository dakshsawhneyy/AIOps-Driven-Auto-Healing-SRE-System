module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = var.enable_single_natgateway

  create_igw = true

  map_public_ip_on_launch = true

  tags = local.common_tags
}


# Package the Lambda function code
data "archive_file" "auto_healer" {
  type        = "zip"
  source_file = "${path.module}/lambda/auto_healer.py"
  output_path = "${path.module}/lambda/auto_healer.zip"
}

#################################
# Auto Healing Lambda
#################################

resource "aws_lambda_function" "auto_healer" {
  filename         = data.archive_file.auto_healer.output_path
  function_name    = "auto-healer"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "auto_healer.handler"
  source_code_hash = data.archive_file.auto_healer.output_base64sha256

  timeout = 400
  runtime = "python3.12"

  layers = [aws_lambda_layer_version.auto_healer_layer.arn]

  environment {
    variables = {
      AUTOHEAL_URL    = "http://autoheal.internal" # placeholder for now
      DYNAMODB_TABLE  = local.dynamodb_table_name
    }
  }

  tags = local.common_tags
}

# Connecting Layer with Lambda
resource "aws_lambda_layer_version" "auto_healer_layer" {
  filename         = "${path.module}/layer.zip" # Path to your local zip file
  layer_name       = "auto_healer_layer"
  compatible_runtimes = ["python3.12"] # Specify compatible runtimes
  source_code_hash = filebase64sha256("${path.module}/layer.zip") # Triggers updates when file changes
}


###################################
# Triggering this lambda through SNS
###################################
resource "aws_sns_topic_subscription" "auto_healer_sub" {
  topic_arn = local.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.auto_healer.arn
}

# Allow SNS to invoke Lambda
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_healer.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = local.sns_topic_arn
}