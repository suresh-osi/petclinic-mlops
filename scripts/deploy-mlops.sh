#!/bin/bash
set -euo pipefail

# ============================================================
# Deploy PetClinic MLOps Infrastructure (us-east-1)
# This does NOT touch the existing ap-south-1 deployment
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/../infrastructure/environments/mlops"
PROJECT_ROOT="${SCRIPT_DIR}/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()     { echo -e "${YELLOW}[mlops] $1${NC}"; }
success() { echo -e "${GREEN}[mlops] ✓ $1${NC}"; }
error()   { echo -e "${RED}[mlops] ✗ $1${NC}" >&2; }
info()    { echo -e "${CYAN}[mlops] $1${NC}"; }

echo ""
echo "============================================================"
echo "  PetClinic MLOps Deployment (us-east-1)"
echo "  NOTE: ap-south-1 deployment is NOT affected"
echo "============================================================"
echo ""

# Pre-flight checks
log "Checking prerequisites..."
command -v terraform > /dev/null 2>&1 || { error "Terraform not installed"; exit 1; }
command -v aws > /dev/null 2>&1 || { error "AWS CLI not installed"; exit 1; }
command -v docker > /dev/null 2>&1 || { error "Docker not installed"; exit 1; }
command -v kubectl > /dev/null 2>&1 || { error "kubectl not installed"; exit 1; }

# Verify AWS credentials
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { error "AWS credentials not configured"; exit 1; }
success "AWS Account: ${ACCOUNT_ID}"

REGION="us-east-1"
export AWS_DEFAULT_REGION=${REGION}

# ============================================================
# Step 1: Create Terraform state bucket (if needed)
# ============================================================
log "Step 1: Ensuring Terraform state bucket exists..."
STATE_BUCKET="petclinic-mlops-tfstate-${ACCOUNT_ID}"
if ! aws s3api head-bucket --bucket "${STATE_BUCKET}" --region ${REGION} 2>/dev/null; then
  aws s3api create-bucket --bucket "${STATE_BUCKET}" --region ${REGION}
  aws s3api put-bucket-versioning --bucket "${STATE_BUCKET}" --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "${STATE_BUCKET}" --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}}]
  }'
  success "Created state bucket: ${STATE_BUCKET}"
else
  success "State bucket exists: ${STATE_BUCKET}"
fi

# ============================================================
# Step 2: Terraform Init & Apply
# ============================================================
log "Step 2: Deploying infrastructure with Terraform..."
cd "${INFRA_DIR}"

# Update backend bucket in main.tf with actual account ID
sed -i "s/petclinic-mlops-tfstate-633426742056/petclinic-mlops-tfstate-${ACCOUNT_ID}/g" main.tf 2>/dev/null || true

terraform init -upgrade
terraform plan -out=tfplan.out
terraform apply -auto-approve tfplan.out
rm -f tfplan.out

success "Infrastructure deployed!"
echo ""

# Capture outputs
EKS_CLUSTER=$(terraform output -raw eks_cluster_name)
ECR_APP=$(terraform output -raw ecr_app_repository_url)
ECR_ML=$(terraform output -raw ecr_ml_repository_url)
ML_BUCKET=$(terraform output -raw ml_data_bucket)

# ============================================================
# Step 3: Build and push Docker images
# ============================================================
log "Step 3: Building and pushing Docker images..."
cd "${PROJECT_ROOT}"

# Login to ECR
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build PetClinic app
log "  Building PetClinic application image..."
docker build -t petclinic-mlops:latest .
docker tag petclinic-mlops:latest ${ECR_APP}:latest
docker push ${ECR_APP}:latest
success "  App image pushed to ECR"

# Build ML container
log "  Building ML model container..."
docker build -t petclinic-ml:latest -f ml/docker/Dockerfile .
docker tag petclinic-ml:latest ${ECR_ML}:latest
docker push ${ECR_ML}:latest
success "  ML image pushed to ECR"

# ============================================================
# Step 4: Upload training data to S3
# ============================================================
log "Step 4: Uploading training data to S3..."
aws s3 cp ml/data/train.csv s3://${ML_BUCKET}/data/train.csv --region ${REGION}
success "Training data uploaded to s3://${ML_BUCKET}/data/"

# ============================================================
# Step 5: Deploy to EKS
# ============================================================
log "Step 5: Deploying PetClinic to EKS..."
aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${REGION}

# Replace account ID in manifest
sed "s/ACCOUNT_ID/${ACCOUNT_ID}/g" k8s/petclinic-deployment.yaml | kubectl apply -f -
success "Application deployed to EKS"

# Wait for deployment
log "  Waiting for pods to be ready..."
kubectl rollout status deployment/petclinic --timeout=300s
success "  Pods are running"

# ============================================================
# Step 6: Get service endpoint
# ============================================================
log "Step 6: Getting service endpoint..."
echo ""
for i in $(seq 1 30); do
  LB_URL=$(kubectl get svc petclinic-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
  if [ -n "${LB_URL}" ]; then
    break
  fi
  sleep 10
done

echo ""
echo "============================================================"
success "DEPLOYMENT COMPLETE!"
echo "============================================================"
echo ""
info "Application URL:  http://${LB_URL:-<pending>}"
info "Prediction API:   http://${LB_URL:-<pending>}/api/predictions/noshow?petAge=10&petType=dog&visitCount=1&previousNoShow=1"
echo ""
info "AWS Console Links (us-east-1):"
info "  EKS Cluster:    https://us-east-1.console.aws.amazon.com/eks/home?region=us-east-1#/clusters/petclinic-eks-cluster"
info "  ECR:            https://us-east-1.console.aws.amazon.com/ecr/repositories?region=us-east-1"
info "  SageMaker:      https://us-east-1.console.aws.amazon.com/sagemaker/home?region=us-east-1#/endpoints"
info "  CodePipeline:   https://us-east-1.console.aws.amazon.com/codesuite/codepipeline/pipelines?region=us-east-1"
info "  CloudWatch:     https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=PetClinic-MLOps"
echo ""
info "kubectl commands:"
info "  kubectl get pods"
info "  kubectl get svc petclinic-service"
info "  kubectl logs -l app=petclinic"
echo ""
echo "============================================================"
