#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/../infrastructure/environments/dev"
PLAN_FILE="${INFRA_DIR}/tfplan.out"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()     { echo -e "${YELLOW}[deploy] $1${NC}"; }
success() { echo -e "${GREEN}[deploy] $1${NC}"; }
error()   { echo -e "${RED}[deploy] $1${NC}" >&2; }

# Pre-flight checks
check_aws_credentials() {
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        error "AWS credentials not configured"
        exit 1
    fi
}

check_terraform() {
    if ! command -v terraform > /dev/null 2>&1; then
        error "Terraform not installed"
        exit 1
    fi
}

log "Checking prerequisites..."
check_terraform
check_aws_credentials

cd "${INFRA_DIR}"

log "Destroying existing infrastructure first..."
# Destroy all resources including force flag
terraform destroy -auto-approve --force || true

# Explicitly delete any remaining Lambda functions (Terraform destroy may not clean them fast enough)
log "Deleting any remaining Lambda functions..."
aws lambda delete-function --function-name NewRelic-PetClinic-LogForwarder --region ap-south-1 || true
aws lambda delete-function --function-name NewRelic-PetClinic-LogForwarder-abc --region ap-south-1 || true

# Wait 2 minutes for AWS to fully clean up all resources
log "Waiting for AWS to fully clean up all resources (this can take several minutes)..."
for i in $(seq 1 12); do
    log "  Wait ${i}/12 (30s each)..."
    sleep 30
done

log "Running terraform init..."
terraform init -upgrade

log "Refreshing Terraform state to prevent drift..."
terraform refresh

log "Running terraform plan (saving to ${PLAN_FILE})..."
terraform plan -out="${PLAN_FILE}"

log "Running terraform apply..."
terraform apply -auto-approve "${PLAN_FILE}"

# Clean up plan file
rm -f "${PLAN_FILE}"

success "Deployment complete!"

# Print ALB DNS for quick validation
ALB_DNS=$(terraform output -raw alb_dns 2>/dev/null || echo "")
if [ -n "${ALB_DNS}" ]; then
    success "ALB endpoint: http://${ALB_DNS}"
    log "Waiting up to 5 minutes for ALB health check to pass..."
    for i in $(seq 1 30); do
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${ALB_DNS}/" 2>/dev/null || echo "000")
        if [ "${HTTP_STATUS}" = "200" ]; then
            success "ALB is healthy! HTTP ${HTTP_STATUS} returned from http://${ALB_DNS}/"
            exit 0
        fi
        log "  attempt ${i}/30 — HTTP ${HTTP_STATUS}, waiting 10s..."
        sleep 10
    done
    error "ALB did not return HTTP 200 after 5 minutes. Check target group health in AWS console."
    exit 1
fi
