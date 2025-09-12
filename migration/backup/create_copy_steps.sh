#!/bin/bash
# Generate copy step files for straight table copies

# Array of tables in dependency order (from config)
copy_tables=(
    "11:accounts:Account Information"
    "12:users:User Accounts" 
    "13:accounts_users:Account User Relationships"
    "14:brands:Product Brands"
    "15:vendors:Vendor Information"
    "16:ingredient_types:Ingredient Type Categories"
    "17:product_types:Product Type Categories"
    "18:ingredients:Ingredient Master Data"
    "19:products:Product Master Data"
    "20:tasks:Task Definitions"
    "21:workers:Worker Information"
)

for table_info in "${copy_tables[@]}"; do
    IFS=':' read -r step_num table_name step_desc <<< "$table_info"
    
    cat > "${step_num}_copy_${table_name}.sh" << EOF
#!/bin/bash
# Migration Step ${step_num}: Copy ${step_desc}
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source migration/common.sh

STEP_NAME="Copy ${step_desc}"
STEP_DESC="Straight copy of ${table_name} table from production to test"

log_step_start "\$STEP_NAME"

check_tunnels || exit 1

if copy_table "${table_name}" "${step_desc}"; then
    log_step_success "\$STEP_NAME" "${step_desc} copied successfully"
else
    log_step_error "\$STEP_NAME" "${step_desc} copy failed"
    exit 1
fi
EOF
    
    chmod +x "${step_num}_copy_${table_name}.sh"
    echo "Created: ${step_num}_copy_${table_name}.sh"
done

echo "All copy step files created!"