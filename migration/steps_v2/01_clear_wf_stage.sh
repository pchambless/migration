#!/bin/bash
# Migration Step 1: Clear wf_stage database
# Drops existing tables to prepare for fresh staging data

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="01 - Clear Staging Database"
STEP_DESC="Clear wf_stage database for fresh staging data"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

# Ensure wf_stage database exists
mysql --defaults-group-suffix=-test -e "CREATE DATABASE IF NOT EXISTS wf_stage;" || {
    error "Failed to create wf_stage database"
    exit 1
}

# Clear all tables from wf_stage (order doesn't matter with FK checks disabled)
log "Clearing wf_stage database..."

mysql --defaults-group-suffix=-test -e "
    SET FOREIGN_KEY_CHECKS = 0;
    DROP TABLE IF EXISTS wf_stage.accounts;
    DROP TABLE IF EXISTS wf_stage.accounts_users;
    DROP TABLE IF EXISTS wf_stage.brands;
    DROP TABLE IF EXISTS wf_stage.global_measure_units;
    DROP TABLE IF EXISTS wf_stage.ingredients;
    DROP TABLE IF EXISTS wf_stage.ingredient_batches;
    DROP TABLE IF EXISTS wf_stage.ingredient_types;
    DROP TABLE IF EXISTS wf_stage.products;
    DROP TABLE IF EXISTS wf_stage.product_batches;
    DROP TABLE IF EXISTS wf_stage.product_batch_ingredients;
    DROP TABLE IF EXISTS wf_stage.product_batch_tasks;
    DROP TABLE IF EXISTS wf_stage.product_recipes;
    DROP TABLE IF EXISTS wf_stage.product_types;
    DROP TABLE IF EXISTS wf_stage.tasks;
    DROP TABLE IF EXISTS wf_stage.users;
    DROP TABLE IF EXISTS wf_stage.vendors;
    DROP TABLE IF EXISTS wf_stage.workers;
    SET FOREIGN_KEY_CHECKS = 1;
" || {
    error "Failed to clear wf_stage database"
    exit 1
}

success "wf_stage database cleared successfully"
log_step_success "$STEP_NAME" "Staging database ready for fresh data"