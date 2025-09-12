#!/bin/bash
# Migration Step 16: Convert Recipe Batches
# Calls: wf_meta.convertRcpeBtch()

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="Convert Recipe Batches"
STEP_DESC="Convert Recipe Batches from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "convertRcpeBtch" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Convert Recipe Batches completed"
else
    log_step_error "$STEP_NAME" "Convert Recipe Batches failed"
    exit 1
fi
