# Main Terraform configuration file
# This file references all other modules and resources

terraform {
  backend "s3" {
    bucket  = "petclinic-tfstate-633426742056"
    key     = "environments/dev/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}

data "aws_caller_identity" "current" {}

