#!/bin/bash
# Migration Step 15: Convert Product Batches
# Calls: wf_meta.convertProdBtch()

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="Convert Product Batches"
STEP_DESC="Convert Product Batches from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "convertProdBtch" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Convert Product Batches completed"
else
    log_step_error "$STEP_NAME" "Convert Product Batches failed"
    exit 1
fi
