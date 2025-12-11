terraform {
  backend "s3" {
    bucket         = "aiops-platform-sf"
    region         = "ap-south-1"
    key            = "serverless-chaos_labeler/terraform.tfstate"
    dynamodb_table = "terraform-lock"
  }
}