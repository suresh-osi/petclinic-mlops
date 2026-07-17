#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/../infrastructure/environments/dev"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

log()     { echo -e "$1"; }
warn()    { echo -e "${YELLOW}[destroy] $1${NC}"; }
success() { echo -e "${GREEN}[destroy] $1${NC}"; }
error()   { echo -e "${RED}[destroy] $1${NC}" >&2; }

warn "WARNING: This will destroy all infrastructure in the dev environment!"
read -p "Are you sure? (yes/no): " CONFIRM

if [ "${CONFIRM}" != "yes" ]; then
    log "Destroy cancelled."
    exit 0
fi

cd "${INFRA_DIR}"

log "Running terraform destroy..."
terraform destroy -auto-approve

success "Destruction complete!"
