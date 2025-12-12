# Capturing AWS Created Infrastructure from its bucket and using them in Serverless Stack
data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = "aiops-platform-sf"
    key    = "aws/terraform.tfstate"
    region = "ap-south-1"
  }
}

locals {

  kinesis_stream_arn = data.terraform_remote_state.aws.outputs.kinesis_stream_arn
  kinesis_stream_name = data.terraform_remote_state.aws.outputs.kinesis_stream_name
  kinesis_normalizer_stream_arn = data.terraform_remote_state.aws.outputs.normalizer_kinesis_stream_arn
  kinesis_normalizer_stream_name = data.terraform_remote_state.aws.outputs.normalizer_kinesis_stream_name

  common_tags = {
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedBy   = "DakshSawhney"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}