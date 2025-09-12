#!/bin/bash
# Migration Step 21: Convert Indices
# Calls: wf_meta.convertIndices()

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="12 - Add Indices and active columns"
STEP_DESC="Convert Indices from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "convertIndices" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Convert Indices completed"
else
    log_step_error "$STEP_NAME" "Convert Indices failed"
    exit 1
fi
