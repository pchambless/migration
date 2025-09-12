#!/bin/bash
# Renumber migration steps for correct execution order
# New order: Drop(01) -> Copy(02-12) -> Convert(13-21)

set -euo pipefail

echo "🔄 Renumbering migration steps..."

# Backup old files
mkdir -p backup
cp *.sh backup/ 2>/dev/null || true

# Renumber conversion procedures from 02-10 to 13-21
echo "Renumbering conversion procedures..."

# Map old numbers to new numbers
declare -A conversion_mapping=(
    ["02_convertIngrBtch.sh"]="13_convertIngrBtch.sh"
    ["03_convertProd.sh"]="14_convertProd.sh"
    ["04_convertProdBtch.sh"]="15_convertProdBtch.sh"
    ["05_convertRcpeBtch.sh"]="16_convertRcpeBtch.sh"
    ["06_convertTaskBtch.sh"]="17_convertTaskBtch.sh"
    ["07_convertProdIngr_Map.sh"]="18_convertProdIngr_Map.sh"
    ["08_createShopEvent.sh"]="19_createShopEvent.sh"
    ["09_ConvertMeasureUnits.sh"]="20_ConvertMeasureUnits.sh"
    ["10_convertIndices.sh"]="21_convertIndices.sh"
)

# Move conversion files
for old_file in "${!conversion_mapping[@]}"; do
    new_file="${conversion_mapping[$old_file]}"
    if [[ -f "$old_file" ]]; then
        # Update step number in content
        sed "s/Step [0-9][0-9]*/Step ${new_file:0:2}/" "$old_file" > "$new_file"
        chmod +x "$new_file"
        rm "$old_file"
        echo "  $old_file → $new_file"
    fi
done

echo "Conversion procedures renumbered!"

# Now create copy steps 02-12
echo "Creating copy steps..."

# Copy tables in dependency order
copy_tables=(
    "02:accounts:Account Information"
    "03:users:User Accounts" 
    "04:accounts_users:Account User Relationships"
    "05:brands:Product Brands"
    "06:vendors:Vendor Information"
    "07:ingredient_types:Ingredient Type Categories"
    "08:product_types:Product Type Categories"
    "09:ingredients:Ingredient Master Data"
    "10:products:Product Master Data"
    "11:tasks:Task Definitions"
    "12:workers:Worker Information"
)

for table_info in "${copy_tables[@]}"; do
    IFS=':' read -r step_num table_name step_desc <<< "$table_info"
    
    cat > "${step_num}_copy_${table_name}.sh" << EOF
#!/bin/bash
# Migration Step ${step_num}: Copy ${step_desc}
# Straight copy from production to test (no UUID conversion)

set -euo pipefail

source common.sh

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
    echo "  Created: ${step_num}_copy_${table_name}.sh"
done

echo ""
echo "✅ Renumbering complete!"
echo ""
echo "New migration order:"
echo "  01. Drop tables"
echo "  02-12. Copy reference tables"
echo "  13-21. Run conversion procedures"
echo ""
echo "Updated files:"
ls -la [0-9][0-9]_*.sh | sort