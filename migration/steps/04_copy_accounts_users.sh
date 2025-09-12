#!/bin/bash
# Migration Step 04: Copy Account User Relationships
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Account User Relationships"
STEP_DESC="Straight copy of accounts_users table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "accounts_users" "Account User Relationships"; then
    log_step_success "$STEP_NAME" "Account User Relationships copied successfully"
else
    log_step_error "$STEP_NAME" "Account User Relationships copy failed"
    exit 1
fi
