#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/../infrastructure/environments/dev"

log() { echo -e "$1"; }

log "Getting ALB DNS name..."
ALB_DNS=$(terraform -chdir="${INFRA_DIR}" output -raw alb_dns 2>/dev/null)

if [ -z "$ALB_DNS" ]; then
    log "ALB DNS not available yet"
    exit 1
fi

log "ALB DNS: ${ALB_DNS}"
log "Checking ALB health..."

# Check ALB endpoint
if curl -sf "http://${ALB_DNS}" > /dev/null; then
    log "ALB is healthy and responding"
else
    log "ALB health check failed"
    exit 1
fi

log "Validation complete!"
