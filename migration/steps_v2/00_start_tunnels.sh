#!/bin/bash
# Migration Step 00: Start SSH Tunnels
# Ensures both production and test tunnels are running before migration

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="00 - Start SSH Tunnels"
STEP_DESC="Start production and test SSH tunnels for migration"

log_step_start "$STEP_NAME"

log "Checking SSH tunnel status..."

# Check if tunnels are already running
if check_tunnels; then
    log "Tunnels already running - skipping tunnel startup"
    log_step_success "$STEP_NAME" "SSH tunnels confirmed active"
    exit 0
fi

# Start both tunnels
log "Starting SSH tunnel manager..."
if ./tunnel_manager_v2.sh start; then
    # Give tunnels time to establish
    log "Waiting 5 seconds for tunnels to establish..."
    sleep 5
    
    # Verify both tunnels are accessible
    if check_tunnels; then
        success "Both SSH tunnels started and accessible"
        log_step_success "$STEP_NAME" "SSH tunnels started successfully"
    else
        error "Tunnels started but not accessible - please check configuration"
        log_step_error "$STEP_NAME" "Tunnel accessibility check failed"
        exit 1
    fi
else
    error "Failed to start SSH tunnels"
    log_step_error "$STEP_NAME" "Tunnel startup failed"
    exit 1
fi