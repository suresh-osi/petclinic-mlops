# ============================================================
# PetClinic MLOps Infrastructure - us-east-1
# Completely separate from the ap-south-1 PetClinic deployment
# ============================================================

terraform {
  backend "s3" {
    bucket  = "petclinic-mlops-tfstate-633426742056"
    key     = "environments/mlops/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
