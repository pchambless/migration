#!/bin/bash
# Migration Step 14: Convert Products  
# Calls: wf_meta.convertProd

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="Convert Products"
STEP_DESC="Converting products from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "convertProd" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Products converted"
else
    log_step_error "$STEP_NAME" "Product conversion failed"
    exit 1
fi