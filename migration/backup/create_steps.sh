#!/bin/bash
# Generate all migration step files

# Array of procedures in order (from your orchestrator)
procedures=(
    "04:convertProdBtch:Convert Product Batches"
    "05:convertRcpeBtch:Convert Recipe Batches" 
    "06:convertTaskBtch:Convert Task Batches"
    "07:convertProdIngr_Map:Convert Product Ingredient Mapping"
    "08:createShopEvent:Create Shop Events"
    "09:ConvertMeasureUnits:Convert Measure Units"
    "10:convertIndices:Convert Indices"
)

for proc_info in "${procedures[@]}"; do
    IFS=':' read -r step_num proc_name step_desc <<< "$proc_info"
    
    cat > "${step_num}_${proc_name}.sh" << EOF
#!/bin/bash
# Migration Step ${step_num}: ${step_desc}
# Calls: wf_meta.${proc_name}()

set -euo pipefail

source ../migration/common.sh

STEP_NAME="${step_desc}"
STEP_DESC="${step_desc} from production to test format"

log_step_start "\$STEP_NAME"

check_tunnels || exit 1

if execute_procedure "${proc_name}" "\$STEP_DESC"; then
    log_step_success "\$STEP_NAME" "${step_desc} completed"
else
    log_step_error "\$STEP_NAME" "${step_desc} failed"
    exit 1
fi
EOF
    
    chmod +x "${step_num}_${proc_name}.sh"
    echo "Created: ${step_num}_${proc_name}.sh"
done

echo "All migration step files created!"