terraform {
  backend "s3" {
    bucket         = "aiops-platform-sf"
    region         = "ap-south-1"
    key            = "auto-heal-engine/terraform.tfstate"
    dynamodb_table = "terraform-lock"
  }
}