#!/bin/bash
# Migration Step 09: Copy Ingredient Master Data
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Ingredient Master Data"
STEP_DESC="Straight copy of ingredients table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "ingredients" "Ingredient Master Data"; then
    log_step_success "$STEP_NAME" "Ingredient Master Data copied successfully"
else
    log_step_error "$STEP_NAME" "Ingredient Master Data copy failed"
    exit 1
fi
