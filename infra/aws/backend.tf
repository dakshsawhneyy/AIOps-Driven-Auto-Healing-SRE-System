terraform {
  backend "s3" {
    bucket         = "aiops-platform-sf"
    region         = "ap-south-1"
    key            = "aws/terraform.tfstate"
    dynamodb_table = "terraform-lock"
  }
}