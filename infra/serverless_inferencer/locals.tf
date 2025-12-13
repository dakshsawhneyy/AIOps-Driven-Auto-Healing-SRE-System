# Capturing AWS Created Infrastructure from its bucket and using them in Serverless Stack
data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = "aiops-platform-sf"
    key    = "aws/terraform.tfstate"
    region = "ap-south-1"
  }
}


# Fetch latest image from ECR
data "aws_ecr_image" "inference" {
  repository_name = "inference"
  image_tag       = "latest"
}

locals {

  sns_topic_arn = data.terraform_remote_state.aws.outputs.sns_topic_arn
  sns_topic_name = data.terraform_remote_state.aws.outputs.sns_topic_name
  dynamodb_table_arn = data.terraform_remote_state.aws.outputs.dynamodb_table_arn
  dynamodb_table_name = data.terraform_remote_state.aws.outputs.dynamodb_table_name
  kinesis_stream_arn = data.terraform_remote_state.aws.outputs.normalizer_kinesis_stream_arn

  ecr_repo_uri = data.aws_ecr_image.inference.image_uri
  ecr_repo_digest = data.aws_ecr_image.inference.image_digest

  common_tags = {
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedBy   = "DakshSawhney"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}