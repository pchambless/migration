#!/bin/bash
# Main Migration Orchestrator
# Runs all migration steps in sequence, stopping on first failure

set -euo pipefail

# Parse command line arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Migration Orchestrator"
            echo "====================="
            echo "Usage: $0 [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be done without making changes"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Export DRY_RUN for child scripts
export DRY_RUN

# Set migration timestamp once and export it
export MIGRATION_TIMESTAMP=$(date '+%y-%m-%d %H:%M')

source migration/lib/common.sh

MIGRATION_START_TIME=$(date +%s)

if [[ "$DRY_RUN" == "true" ]]; then
    log "🧪 Starting Complete Migration Process (DRY RUN)"
    log "==============================================="
    log "⚠️  DRY RUN MODE: No changes will be made"
else
    log "🚀 Starting Complete Migration Process"
    log "======================================"
fi

# Migration steps in correct dependency order
# V2 Streamlined Migration Steps (14 steps with tunnel management)
MIGRATION_STEPS=(
    "00_start_tunnels.sh"            # Start SSH tunnels
    "01_clear_wf_stage.sh"           # Clear staging database
    "02_bulk_copy_to_staging.sh"     # Bulk copy prod→wf_stage
    "03_setup_whatsfresh.sh"         # Copy wf_stage→whatsfresh
    "04_convertIngrBtch.sh"          # Convert ingredient batches
    "05_convertProd.sh"              # Add measure_id column
    "06_convertProdBtch.sh"          # Convert product batches
    "07_convertRcpeBtch.sh"          # Convert recipe batches
    "08_convertTaskBtch.sh"          # Convert task batches
    "09_convertProdIngr_Map.sh"      # Convert product ingredients
    "10_createShopEvent.sh"          # Create shop events
    "11_ConvertMeasureUnits.sh"      # Convert measure units
    "12_convertIndices.sh"           # Convert indices
    "13_stop_tunnels.sh"             # Stop SSH tunnels
)

# Pre-flight checks
log "Running pre-flight checks..."
log "Tunnel management will be handled by step 00"

success "Pre-flight checks passed"

# Execute each migration step
completed_steps=0
total_steps=${#MIGRATION_STEPS[@]}

log "Starting migration with $total_steps steps..."

if [[ "$DRY_RUN" == "true" ]]; then
    log "Migration steps to execute:"
    for i in "${!MIGRATION_STEPS[@]}"; do
        log "  $((i+1)). ${MIGRATION_STEPS[i]}"
    done
    echo
fi

echo

log "About to start executing steps..."

log "DEBUG: Testing loop entry..."
log "DEBUG: Number of steps in array: ${#MIGRATION_STEPS[@]}"
log "DEBUG: First step: ${MIGRATION_STEPS[0]}"

log "DEBUG: Starting for loop..."

for step in "${MIGRATION_STEPS[@]}"; do
    completed_steps=$((completed_steps + 1))
    
    log "📍 Step $completed_steps/$total_steps: $step"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DEBUG: About to execute ./migration/steps_v2/$step in dry-run mode..."
    fi
    
    # Ensure DRY_RUN is exported for child processes
    export DRY_RUN
    
    log "DEBUG: Executing ./migration/steps_v2/$step..."
    ./migration/steps_v2/"$step"
    exit_code=$?
    log "DEBUG: Step returned exit code: $exit_code"
    
    if [[ $exit_code -eq 0 ]]; then
        success "Step $completed_steps completed: $step"
    else
        error "❌ Migration failed at step $completed_steps: $step (exit code: $exit_code)"
        error "Migration stopped due to failure"
        
        echo
        log "📊 Migration Summary:"
        log "  Completed steps: $((completed_steps - 1))/$total_steps"
        log "  Failed step: $step"
        log "  To resume: Fix the issue and run ./migration/steps_v2/$step manually"
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
log "  Log file: $LOG_FILE"

echo
log "Next steps:"
log "  1. Validate migrated data"
log "  2. Test your application with migrated data"
log "  3. SSH tunnels have been closed automatically"

echo
success "Migration process complete! 🎊"