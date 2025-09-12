#!/bin/bash
# Main Migration Orchestrator
# Runs all migration steps in sequence, stopping on first failure

set -euo pipefail

source common.sh

MIGRATION_START_TIME=$(date +%s)

log "🚀 Starting Complete Migration Process"
log "======================================"

# Migration steps in order
MIGRATION_STEPS=(
    "01_drop_tables.sh"
    "02_convertIngrBtch.sh" 
    "03_convertProd.sh"
    "04_convertProdBtch.sh"
    "05_convertRcpeBtch.sh"
    "06_convertTaskBtch.sh"
    "07_convertProdIngr_Map.sh"
    "08_createShopEvent.sh"
    "09_ConvertMeasureUnits.sh"
    "10_convertIndices.sh"
)

# Pre-flight checks
log "Running pre-flight checks..."
check_tunnels || {
    error "Tunnel check failed. Please run: ./session/start.sh"
    exit 1
}

success "Pre-flight checks passed"

# Execute each migration step
local completed_steps=0
local total_steps=${#MIGRATION_STEPS[@]}

log "Starting migration with $total_steps steps..."
echo

for step in "${MIGRATION_STEPS[@]}"; do
    ((completed_steps++))
    
    log "📍 Step $completed_steps/$total_steps: $step"
    
    if ./"$step"; then
        success "Step $completed_steps completed: $step"
    else
        error "❌ Migration failed at step $completed_steps: $step"
        error "Migration stopped due to failure"
        
        echo
        log "📊 Migration Summary:"
        log "  Completed steps: $((completed_steps - 1))/$total_steps"
        log "  Failed step: $step"
        log "  To resume: Fix the issue and run ./$step manually"
        log "  Then continue with remaining steps"
        
        exit 1
    fi
    
    echo
done

# Migration completed successfully
MIGRATION_END_TIME=$(date +%s)
TOTAL_DURATION=$((MIGRATION_END_TIME - MIGRATION_START_TIME))

echo
echo "================================================================="
success "🎉 MIGRATION COMPLETED SUCCESSFULLY!"
echo "================================================================="
log "📊 Final Summary:"
log "  Total steps: $total_steps"
log "  All steps completed successfully"
log "  Total duration: ${TOTAL_DURATION}s"
log "  Log file: $LOG_DIR/migration_$TIMESTAMP.log"

echo
log "Next steps:"
log "  1. Validate migrated data"
log "  2. Run ./session/stop.sh to close tunnels"
log "  3. Test your application with migrated data"

echo
success "Migration process complete! 🎊"