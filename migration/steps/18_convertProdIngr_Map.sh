#!/bin/bash
# Migration Step 18: Convert Product Ingredient Mapping
# Calls: wf_meta.convertProdIngr_Map()

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="Convert Product Ingredient Mapping"
STEP_DESC="Convert Product Ingredient Mapping from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "convertProdIngr_Map" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Convert Product Ingredient Mapping completed"
else
    log_step_error "$STEP_NAME" "Convert Product Ingredient Mapping failed"
    exit 1
fi
