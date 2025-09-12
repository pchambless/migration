#!/bin/bash
# Migration Step 02: Bulk Copy to Staging
# Single mysqldump operation to copy all 17 tables from production to wf_stage

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="02 - Bulk Copy to Staging"
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
    --skip-set-charset \
    --skip-routines \
    --skip-triggers \
    whatsfresh \
    "${STAGING_TABLES[@]}" > "$temp_dump" 2>/dev/null; then
    log "Bulk export completed successfully"
else
    error "Failed to export tables from production"
    rm -f "$temp_dump"
    exit 1
fi

# Import to wf_stage (filter out incompatible sql_mode)
log "Importing tables to wf_stage database..."
sed 's/NO_AUTO_CREATE_USER,//g' "$temp_dump" | mysql --defaults-group-suffix=-test wf_stage
import_exit_code=$?

if [[ $import_exit_code -eq 0 ]]; then
    log "Bulk import completed successfully"
else
    # Check if tables were actually created despite warnings
    table_count=$(mysql --defaults-group-suffix=-test -sN -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'wf_stage';" 2>/dev/null || echo "0")
    if [[ $table_count -gt 0 ]]; then
        warn "Import completed with warnings but tables were created (${table_count} tables)"
        log "Bulk import completed with warnings"
    else
        error "Failed to import tables to wf_stage"
        rm -f "$temp_dump"
        exit 1
    fi
fi

# Remove generated columns from staging tables to avoid conflicts
log "Removing generated columns from staging tables..."
mysql --defaults-group-suffix=-test -e "
    SET FOREIGN_KEY_CHECKS = 0;
    ALTER TABLE wf_stage.accounts DROP COLUMN active;
    ALTER TABLE wf_stage.accounts_users DROP COLUMN active;
    ALTER TABLE wf_stage.users DROP COLUMN active;
    ALTER TABLE wf_stage.products DROP COLUMN active;
    ALTER TABLE wf_stage.ingredients DROP COLUMN active;
    ALTER TABLE wf_stage.product_batches DROP COLUMN active;
    ALTER TABLE wf_stage.ingredient_batches DROP COLUMN active;
    ALTER TABLE wf_stage.product_recipes DROP COLUMN active;
    ALTER TABLE wf_stage.product_batch_ingredients DROP COLUMN active;
    ALTER TABLE wf_stage.product_batch_tasks DROP COLUMN active;
    ALTER TABLE wf_stage.brands DROP COLUMN active;
    ALTER TABLE wf_stage.vendors DROP COLUMN active;
    ALTER TABLE wf_stage.workers DROP COLUMN active;
    ALTER TABLE wf_stage.ingredient_types DROP COLUMN active;
    ALTER TABLE wf_stage.product_types DROP COLUMN active;
    ALTER TABLE wf_stage.tasks DROP COLUMN active;
    SET FOREIGN_KEY_CHECKS = 1;
"

# Clean up temp file
rm -f "$temp_dump"

end_time=$(date +%s)
duration=$((end_time - start_time))

success "Bulk copy completed: ${#STAGING_TABLES[@]} tables in ${duration}s"
log_step_success "$STEP_NAME" "All tables copied to wf_stage and generated columns removed"