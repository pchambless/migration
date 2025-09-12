#!/bin/bash
# Migration Step 13: Convert Ingredient Batches
# Calls: wf_meta.convertIngrBtch()

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="Convert Ingredient Batches" 
STEP_DESC="Converting ingredient batches from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "convertIngrBtch" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Ingredient batches converted"
else
    log_step_error "$STEP_NAME" "Ingredient batch conversion failed"
    exit 1
fi