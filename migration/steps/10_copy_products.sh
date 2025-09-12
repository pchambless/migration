#!/bin/bash
# Migration Step 10: Copy Product Master Data
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Product Master Data"
STEP_DESC="Straight copy of products table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "products" "Product Master Data"; then
    log_step_success "$STEP_NAME" "Product Master Data copied successfully"
else
    log_step_error "$STEP_NAME" "Product Master Data copy failed"
    exit 1
fi
