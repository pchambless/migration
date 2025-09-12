#!/bin/bash
# Migration Step 08: Create Shop Events
# Calls: wf_meta.createShopEvent()

set -euo pipefail

source ../migration/common.sh

STEP_NAME="Create Shop Events"
STEP_DESC="Create Shop Events from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "createShopEvent" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Create Shop Events completed"
else
    log_step_error "$STEP_NAME" "Create Shop Events failed"
    exit 1
fi
