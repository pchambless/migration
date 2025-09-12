#!/bin/bash
# Migration Step 12: Copy Worker Information
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Worker Information"
STEP_DESC="Straight copy of workers table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "workers" "Worker Information"; then
    log_step_success "$STEP_NAME" "Worker Information copied successfully"
else
    log_step_error "$STEP_NAME" "Worker Information copy failed"
    exit 1
fi
