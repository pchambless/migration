#!/bin/bash
# Migration Step 05: Copy Product Brands
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Product Brands"
STEP_DESC="Straight copy of brands table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "brands" "Product Brands"; then
    log_step_success "$STEP_NAME" "Product Brands copied successfully"
else
    log_step_error "$STEP_NAME" "Product Brands copy failed"
    exit 1
fi
