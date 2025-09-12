#!/bin/bash
# Migration Step 17: Convert Task Batches
# Calls: wf_meta.convertTaskBtch()

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="08 - Convert Task Batches"
STEP_DESC="Convert Task Batches from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "convertTaskBtch" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Convert Task Batches completed"
else
    log_step_error "$STEP_NAME" "Convert Task Batches failed"
    exit 1
fi
