#!/bin/bash
# Migration Step 06: Copy Vendor Information
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Vendor Information"
STEP_DESC="Straight copy of vendors table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "vendors" "Vendor Information"; then
    log_step_success "$STEP_NAME" "Vendor Information copied successfully"
else
    log_step_error "$STEP_NAME" "Vendor Information copy failed"
    exit 1
fi
