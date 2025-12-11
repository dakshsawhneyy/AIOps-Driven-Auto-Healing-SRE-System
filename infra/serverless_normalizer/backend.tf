terraform {
  backend "s3" {
    bucket         = "aiops-platform-sf"
    region         = "ap-south-1"
    key            = "serverless-normalizer/terraform.tfstate"
    dynamodb_table = "terraform-lock"
  }
}