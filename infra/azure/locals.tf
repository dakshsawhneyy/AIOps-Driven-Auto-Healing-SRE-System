# Capturing AWS Created Infrastructure from its bucket and using them in Azure
data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = "aiops-platform-sf"
    key    = "aws/terraform.tfstate"
    region = "ap-south-1"
  }
}


locals {
  log_group_name = data.terraform_remote_state.aws.outputs.log_group_name
  kinesis_stream_name = data.terraform_remote_state.aws.outputs.kinesis_stream_name
  fluentbit_access_key = data.terraform_remote_state.aws.outputs.fluentbit_access_key
  fluentbit_secret_key = data.terraform_remote_state.aws.outputs.fluentbit_secret_key
  aws_region = "ap-south-1"

  common_tags = {
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedBy   = "DakshSawhney"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}