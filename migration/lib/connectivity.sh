#!/bin/bash
# Connectivity and tunnel management

# Check if tunnels are active
check_tunnels() {
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run "Would check tunnel connectivity on ports $PROD_PORT and $TEST_PORT"
        dry_run "Tunnel connectivity check bypassed in dry-run mode"
        return 0
    fi
    
    log "Checking tunnel status..."
    
    if ! nc -z localhost "$PROD_PORT" 2>/dev/null; then
        error "Production tunnel not accessible on port $PROD_PORT"
        error "Run: ./session/start.sh prodServer"
        return 1
    fi
    
    if ! nc -z localhost "$TEST_PORT" 2>/dev/null; then
        error "Test server tunnel not accessible on port $TEST_PORT" 
        error "Run: ./session/start.sh testServer"
        return 1
    fi
    
    success "Both tunnels are accessible"
}