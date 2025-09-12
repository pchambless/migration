#!/bin/bash
# Migration Step 3: Setup whatsfresh database
# Calls copyToWhatsfresh procedure to clear whatsfresh and copy base tables from staging

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="03 - Setup Whatsfresh Database" 
STEP_DESC="Clear whatsfresh and copy base tables from wf_stage"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "copyToWhatsfresh" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Base tables copied to whatsfresh successfully"
else
    log_step_error "$STEP_NAME" "Failed to setup whatsfresh database"
    exit 1
fi