#!/bin/bash
# Migration Step 07: Copy Ingredient Type Categories
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Ingredient Type Categories"
STEP_DESC="Straight copy of ingredient_types table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "ingredient_types" "Ingredient Type Categories"; then
    log_step_success "$STEP_NAME" "Ingredient Type Categories copied successfully"
else
    log_step_error "$STEP_NAME" "Ingredient Type Categories copy failed"
    exit 1
fi
