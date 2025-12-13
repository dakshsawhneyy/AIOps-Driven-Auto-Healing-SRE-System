data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Capturing AWS Created Infrastructure from its bucket and using them in Serverless Stack
data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = "aiops-platform-sf"
    key    = "aws/terraform.tfstate"
    region = "ap-south-1"
  }
}

data "aws_secretsmanager_secret" "aiops-secret" {
  name = "AIOps-Platform-Secrets"
}

locals {

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 10)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k)]

  
  sns_topic_arn = data.terraform_remote_state.aws.outputs.sns_topic_arn
  sns_topic_name = data.terraform_remote_state.aws.outputs.sns_topic_name

  dynamodb_table_arn = data.terraform_remote_state.aws.outputs.dynamodb_table_arn
  dynamodb_table_name = data.terraform_remote_state.aws.outputs.dynamodb_table_name

  common_tags = {
    Project     = var.project_name
    ManagedBy   = "terraform"
    CreatedBy   = "DakshSawhney"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}