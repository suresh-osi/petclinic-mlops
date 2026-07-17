#!/bin/bash
set -euo pipefail

# ============================================================
# PetClinic MLOps Environment Setup Script
# ============================================================
# This script sets up the MLOps environment:
# 1. Creates S3 bucket for ML data
# 2. Pushes ML training container to ECR
# 3. Uploads training data
# 4. Creates SageMaker Pipeline
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
INFRA_DIR="${PROJECT_ROOT}/infrastructure/environments/dev"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()     { echo -e "${YELLOW}[mlops-setup] $1${NC}"; }
success() { echo -e "${GREEN}[mlops-setup] $1${NC}"; }
error()   { echo -e "${RED}[mlops-setup] $1${NC}" >&2; }

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="ap-south-1"

log "AWS Account: ${ACCOUNT_ID}"
log "Region: ${REGION}"

# Step 1: Terraform apply for base MLOps infrastructure (ECR, S3, IAM)
log "Step 1: Deploying base MLOps infrastructure..."
cd "${INFRA_DIR}"
terraform init -upgrade
terraform plan -target=aws_ecr_repository.petclinic_app \
              -target=aws_ecr_repository.petclinic_ml \
              -target=aws_s3_bucket.ml_data \
              -target=aws_iam_role.sagemaker_execution_role \
              -target=aws_sagemaker_model_package_group.petclinic
terraform apply -auto-approve \
              -target=aws_ecr_repository.petclinic_app \
              -target=aws_ecr_repository.petclinic_ml \
              -target=aws_s3_bucket.ml_data \
              -target=aws_iam_role.sagemaker_execution_role \
              -target=aws_sagemaker_model_package_group.petclinic

# Step 2: Build and push ML container to ECR
log "Step 2: Building and pushing ML container..."
cd "${PROJECT_ROOT}"
ECR_ML_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/petclinic-ml"

aws ecr get-login-password --region ${REGION} | \
  docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

docker build -t petclinic-ml:latest -f ml/docker/Dockerfile .
docker tag petclinic-ml:latest ${ECR_ML_REPO}:latest
docker push ${ECR_ML_REPO}:latest

# Step 3: Upload training data to S3
log "Step 3: Uploading training data to S3..."
aws s3 cp ml/data/train.csv s3://petclinic-ml-data-${ACCOUNT_ID}/data/train.csv

# Step 4: Build PetClinic Docker image
log "Step 4: Building PetClinic application container..."
ECR_APP_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/petclinic"
docker build -t petclinic:latest .
docker tag petclinic:latest ${ECR_APP_REPO}:latest
docker push ${ECR_APP_REPO}:latest

success "============================================================"
success "MLOps environment setup complete!"
success "============================================================"
success ""
success "Resources created:"
success "  - ECR Repository (App): ${ECR_APP_REPO}"
success "  - ECR Repository (ML):  ${ECR_ML_REPO}"
success "  - S3 Bucket (ML Data):  petclinic-ml-data-${ACCOUNT_ID}"
success "  - SageMaker Model Group: petclinic-noshow-models"
success ""
success "Next steps:"
success "  1. Create CodeStar connection to GitHub (AWS Console)"
success "  2. Update codestar_connection_arn in terraform.tfvars"
success "  3. Run 'terraform apply' to deploy CodePipeline"
success "  4. Set deploy_eks=true in terraform.tfvars for EKS deployment"
success "  5. Set deploy_sagemaker_endpoint=true after first model training"
success "============================================================"
