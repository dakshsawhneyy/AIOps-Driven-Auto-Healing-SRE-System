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
  role_arn            = data.terraform_remote_state.aws.outputs.fluentbit_role_arn

  common_tags = {
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedBy   = "DakshSawhney"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
}