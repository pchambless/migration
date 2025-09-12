#!/bin/bash
# Migration Step 11: Copy Task Definitions
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/lib/common.sh

STEP_NAME="Copy Task Definitions"
STEP_DESC="Straight copy of tasks table from production to test"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if copy_table "tasks" "Task Definitions"; then
    log_step_success "$STEP_NAME" "Task Definitions copied successfully"
else
    log_step_error "$STEP_NAME" "Task Definitions copy failed"
    exit 1
fi
