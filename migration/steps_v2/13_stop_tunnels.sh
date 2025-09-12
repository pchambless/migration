#!/bin/bash
# Migration Step 13: Stop SSH Tunnels
# Cleanly closes SSH tunnels after migration completion

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="13 - Stop SSH Tunnels"
STEP_DESC="Close SSH tunnels after migration completion"

log_step_start "$STEP_NAME"

log "Stopping SSH tunnels..."

# Stop both tunnels using tunnel manager
if ./tunnel_manager_v2.sh stop; then
    success "SSH tunnels stopped successfully"
    log_step_success "$STEP_NAME" "SSH tunnels closed cleanly"
else
    warn "Tunnel manager reported issues, but migration completed successfully"
    log_step_success "$STEP_NAME" "Migration complete (tunnel cleanup attempted)"
fi

log "Migration cleanup complete"