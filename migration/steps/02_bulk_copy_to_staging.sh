#!/bin/bash
# Migration Step 02: Bulk Copy to Staging
# Single mysqldump operation to copy all 17 tables from production to wf_stage

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="Bulk Copy to Staging"
STEP_DESC="Copy 17 tables from production to wf_stage database"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

# Tables to copy to staging for UUID conversions
STAGING_TABLES=(
    "accounts" "accounts_users" "brands" "global_measure_units"
    "ingredients" "ingredient_batches" "ingredient_types"
    "products" "product_batches" "product_batch_ingredients"
    "product_batch_tasks" "product_recipes" "product_types"
    "tasks" "users" "vendors" "workers"
)

log "Bulk copying ${#STAGING_TABLES[@]} tables to wf_stage database..."

# Ensure wf_stage database exists
log "Ensuring wf_stage database exists..."
mysql --defaults-group-suffix=-test -e "CREATE DATABASE IF NOT EXISTS wf_stage;" || {
    error "Failed to create wf_stage database"
    exit 1
}

start_time=$(date +%s)

# Create temporary dump file
temp_dump="/tmp/bulk_staging_dump_$$.sql"

# Single mysqldump for all tables
log "Exporting ${#STAGING_TABLES[@]} tables from production..."
if mysqldump --defaults-group-suffix=-prod \
    --single-transaction \
    --add-drop-table \
    whatsfresh \
    "${STAGING_TABLES[@]}" > "$temp_dump" 2>/dev/null; then
    log "Bulk export completed successfully"
else
    error "Failed to export tables from production"
    rm -f "$temp_dump"
    exit 1
fi

# Import to wf_stage
log "Importing tables to wf_stage database..."
if mysql --defaults-group-suffix=-test wf_stage < "$temp_dump" 2>/dev/null; then
    log "Bulk import completed successfully"
else
    error "Failed to import tables to wf_stage"
    rm -f "$temp_dump"
    exit 1
fi

# Clean up temp file
rm -f "$temp_dump"

end_time=$(date +%s)
duration=$((end_time - start_time))

success "Bulk copy completed: ${#STAGING_TABLES[@]} tables in ${duration}s"
log_step_success "$STEP_NAME" "All tables copied to wf_stage successfully"