#!/bin/bash
# Migration Step 03: Copy User Accounts
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy User Accounts"
STEP_DESC="Straight copy of users table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "users" "User Accounts"; then
    log_step_success "$STEP_NAME" "User Accounts copied successfully"
else
    log_step_error "$STEP_NAME" "User Accounts copy failed"
    exit 1
fi
