#!/bin/bash
# Migration Step 1: Drop tables in dependency order
# This step clears existing tables to prepare for fresh data

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="Drop Tables"
STEP_DESC="Dropping tables in dependency order (foreign key safe)"

log_step_start "$STEP_NAME"

# Tables to drop in order (from config)
readarray -t TABLES < <(jq -r '.cleanup_order[]' "$CONFIG")

if [[ ${#TABLES[@]} -eq 0 ]]; then
    error "No cleanup_order found in configuration"
    exit 1
fi

log "Dropping ${#TABLES[@]} tables in dependency order..."

# Connect to test server and drop tables
log "Connecting to test server (localhost:$TEST_PORT)..."

if [[ "$DRY_RUN" == "true" ]]; then
    dry_run "Would disable foreign key checks: SET FOREIGN_KEY_CHECKS = 0"
    for table in "${TABLES[@]}"; do
        if [[ -n "$table" && "$table" != "null" ]]; then
            dry_run "Would drop table: DROP TABLE IF EXISTS whatsfresh.$table"
        fi
    done
    dry_run "Would re-enable foreign key checks: SET FOREIGN_KEY_CHECKS = 1"
    log_step_success "$STEP_NAME" "Tables would be dropped (dry-run)"
    exit 0
fi

# Disable foreign key checks for faster dropping
mysql --defaults-group-suffix=-test -e "SET FOREIGN_KEY_CHECKS = 0;" || {
    error "Failed to disable foreign key checks"
    exit 1
}

failed_tables=()
success_count=0

for table in "${TABLES[@]}"; do
    if [[ -n "$table" && "$table" != "null" ]]; then
        log "  Dropping table: whatsfresh.$table"
        
        if mysql --defaults-group-suffix=-test -e "DROP TABLE IF EXISTS whatsfresh.$table;" 2>/dev/null; then
            success "    ✓ $table dropped"
            success_count=$((success_count + 1))
        else
            warn "    ⚠ Failed to drop $table (may not exist)"
            failed_tables+=("$table")
        fi
    fi
done

# Re-enable foreign key checks
mysql --defaults-group-suffix=-test -e "SET FOREIGN_KEY_CHECKS = 1;" || {
    warn "Failed to re-enable foreign key checks"
}

log "Drop Summary:"
log "  Successful: $success_count"
log "  Failed: ${#failed_tables[@]}"

if [[ ${#failed_tables[@]} -gt 0 ]]; then
    warn "Failed tables: ${failed_tables[*]}"
fi

log_step_success "$STEP_NAME" "Tables dropped successfully"