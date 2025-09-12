#!/bin/bash
# Migration Step 1: Drop tables in dependency order
# This step clears existing tables to prepare for fresh data

set -euo pipefail

source ../migration/common.sh

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

# Disable foreign key checks for faster dropping
mysql -h localhost -P "$TEST_PORT" -u root -p -e "SET FOREIGN_KEY_CHECKS = 0;" || {
    error "Failed to disable foreign key checks"
    exit 1
}

local failed_tables=()
local success_count=0

for table in "${TABLES[@]}"; do
    if [[ -n "$table" && "$table" != "null" ]]; then
        log "  Dropping table: whatsfresh.$table"
        
        if mysql -h localhost -P "$TEST_PORT" -u root -p -e "DROP TABLE IF EXISTS whatsfresh.$table;" 2>/dev/null; then
            success "    ✓ $table dropped"
            ((success_count++))
        else
            warn "    ⚠ Failed to drop $table (may not exist)"
            failed_tables+=("$table")
        fi
    fi
done

# Re-enable foreign key checks
mysql -h localhost -P "$TEST_PORT" -u root -p -e "SET FOREIGN_KEY_CHECKS = 1;" || {
    warn "Failed to re-enable foreign key checks"
}

log "Drop Summary:"
log "  Successful: $success_count"
log "  Failed: ${#failed_tables[@]}"

if [[ ${#failed_tables[@]} -gt 0 ]]; then
    warn "Failed tables: ${failed_tables[*]}"
fi

log_step_success "$STEP_NAME" "Tables dropped successfully"