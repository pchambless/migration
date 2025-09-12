#!/bin/bash
# Migration Step 02: Copy Account Information
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Account Information"
STEP_DESC="Straight copy of accounts table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "accounts" "Account Information"; then
    log_step_success "$STEP_NAME" "Account Information copied successfully"
else
    log_step_error "$STEP_NAME" "Account Information copy failed"
    exit 1
fi
