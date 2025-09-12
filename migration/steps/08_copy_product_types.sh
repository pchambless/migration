#!/bin/bash
# Migration Step 08: Copy Product Type Categories
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Product Type Categories"
STEP_DESC="Straight copy of product_types table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "product_types" "Product Type Categories"; then
    log_step_success "$STEP_NAME" "Product Type Categories copied successfully"
else
    log_step_error "$STEP_NAME" "Product Type Categories copy failed"
    exit 1
fi
