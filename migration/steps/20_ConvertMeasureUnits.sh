#!/bin/bash
# Migration Step 20: Convert Measure Units
# Calls: wf_meta.ConvertMeasureUnits()

set -uo pipefail

source migration/lib/common.sh

STEP_NAME="Convert Measure Units"
STEP_DESC="Convert Measure Units from production to test format"

log_step_start "$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "ConvertMeasureUnits" "$STEP_DESC"; then
    log_step_success "$STEP_NAME" "Convert Measure Units completed"
else
    log_step_error "$STEP_NAME" "Convert Measure Units failed"
    exit 1
fi
