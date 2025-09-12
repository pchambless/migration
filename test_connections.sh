#!/bin/bash
# Database Connection Tester
# SAFE: Only performs READ operations - no writes to production

set -euo pipefail

CONFIG="./config.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Read configuration
SOURCE_DB=$(jq -r '.source' "$CONFIG")
TARGET_DB=$(jq -r '.target' "$CONFIG")
META_DB="wf_meta"

log "🔍 Testing database connections..."
log "Source (PROD): $SOURCE_DB"
log "Target (TEST): $TARGET_DB" 
log "Procedures: $META_DB"

# Test basic connectivity
test_basic_connection() {
    local db_name=$1
    local db_type=$2
    
    log "Testing basic connection to $db_type database: $db_name"
    
    if mysql -u paul "$db_name" -e "SELECT 1 as connection_test" >/dev/null 2>&1; then
        success "✓ Connected to $db_name"
        return 0
    else
        error "✗ Cannot connect to $db_name"
        log "  Check: Database exists, credentials, network access"
        return 1
    fi
}

# Test read access to specific tables
test_table_access() {
    local db_name=$1
    local db_type=$2
    
    log "Testing table access in $db_type database: $db_name"
    
    # Get list of tables to check
    local tables_to_check=()
    
    if [[ "$db_type" == "PRODUCTION" ]]; then
        # Check source tables from config
        readarray -t tables_to_check < <(jq -r '.cleanup_order[]?' "$CONFIG")
        if [[ ${#tables_to_check[@]} -eq 0 ]]; then
            tables_to_check=("ingredient_batches" "product_batches" "products")
        fi
    fi
    
    local accessible_tables=0
    local total_tables=${#tables_to_check[@]}
    
    for table in "${tables_to_check[@]}"; do
        if [[ -n "$table" && "$table" != "null" ]]; then
            log "  Checking table: $table"
            
            # Test if table exists and is readable
            if mysql -u paul "$db_name" -e "SELECT COUNT(*) as row_count FROM $table LIMIT 1" 2>/dev/null; then
                local count=$(mysql -u paul "$db_name" -sN -e "SELECT COUNT(*) FROM $table" 2>/dev/null || echo "unknown")
                success "    ✓ $table accessible ($count rows)"
                ((accessible_tables++))
            else
                warn "    ⚠ $table not accessible or doesn't exist"
            fi
        fi
    done
    
    if [[ $accessible_tables -gt 0 ]]; then
        success "Accessible tables: $accessible_tables/$total_tables"
        return 0
    else
        error "No tables accessible in $db_name"
        return 1
    fi
}

# Test procedure access (read-only)
test_procedure_access() {
    log "Testing stored procedure access in $META_DB"
    
    # Check if we can list procedures (read-only operation)
    if mysql -u paul "$META_DB" -e "
        SELECT ROUTINE_NAME, ROUTINE_TYPE, CREATED 
        FROM information_schema.ROUTINES 
        WHERE ROUTINE_SCHEMA = '$META_DB' 
        AND ROUTINE_TYPE = 'PROCEDURE'
        LIMIT 5
    " 2>/dev/null; then
        success "✓ Can access procedure definitions in $META_DB"
        
        # Check specific procedures from config
        readarray -t PROCS < <(jq -r '.procedures_ordered[]?' "$CONFIG")
        if [[ ${#PROCS[@]} -eq 0 ]]; then
            PROCS=("convertIngrBtch" "convertProd")
        fi
        
        local found_procs=0
        for proc in "${PROCS[@]::3}"; do  # Check first 3 procedures only
            if [[ -n "$proc" && "$proc" != "null" ]]; then
                local exists=$(mysql -u paul "$META_DB" -sN -e "
                    SELECT COUNT(*) 
                    FROM information_schema.ROUTINES 
                    WHERE ROUTINE_SCHEMA = '$META_DB' 
                    AND ROUTINE_NAME = '$proc'
                " 2>/dev/null || echo "0")
                
                if [[ "$exists" -gt 0 ]]; then
                    success "  ✓ Procedure $proc exists"
                    ((found_procs++))
                else
                    warn "  ⚠ Procedure $proc not found"
                fi
            fi
        done
        
        log "Found procedures: $found_procs/${#PROCS[@]}"
        return 0
    else
        error "✗ Cannot access procedures in $META_DB"
        return 1
    fi
}

# Test sample data extraction (safe read-only)
test_sample_extraction() {
    log "Testing sample data extraction (READ-ONLY)"
    
    local test_table="ingredient_batches"
    
    log "Extracting 3 sample rows from $SOURCE_DB.$test_table"
    
    if mysql -u paul "$SOURCE_DB" -e "
        SELECT 'SAMPLE DATA EXTRACTION TEST' as test_header;
        SELECT id, ingredient_id, lot_number, purchase_date, created_at 
        FROM $test_table 
        ORDER BY created_at DESC 
        LIMIT 3;
        SELECT 'END SAMPLE' as test_footer;
    " 2>/dev/null; then
        success "✓ Sample data extraction successful"
        return 0
    else
        warn "⚠ Could not extract sample data from $test_table"
        return 1
    fi
}

# Show database info
show_database_info() {
    local db_name=$1
    
    log "Database information for: $db_name"
    
    # Show database version and basic info
    mysql -u paul "$db_name" -e "
        SELECT 
            VERSION() as mysql_version,
            DATABASE() as current_database,
            USER() as connected_as,
            NOW() as server_time
    " 2>/dev/null || warn "Could not retrieve database info for $db_name"
}

# Main test sequence
main() {
    log "🚀 Starting connection tests..."
    log "⚠️  NOTE: All tests are READ-ONLY - no data will be modified!"
    
    local tests_passed=0
    local total_tests=0
    
    # Test 1: Production database connection
    ((total_tests++))
    log "═══════════════════════════════════════"
    log "TEST 1: Production Database Connection"
    if test_basic_connection "$SOURCE_DB" "PRODUCTION"; then
        show_database_info "$SOURCE_DB"
        ((tests_passed++))
    fi
    
    # Test 2: Production table access
    ((total_tests++))
    log "═══════════════════════════════════════"
    log "TEST 2: Production Table Access"
    if test_table_access "$SOURCE_DB" "PRODUCTION"; then
        ((tests_passed++))
    fi
    
    # Test 3: Target database connection
    ((total_tests++))
    log "═══════════════════════════════════════"
    log "TEST 3: Target Database Connection"
    if test_basic_connection "$TARGET_DB" "TARGET"; then
        show_database_info "$TARGET_DB"
        ((tests_passed++))
    fi
    
    # Test 4: Procedure access
    ((total_tests++))
    log "═══════════════════════════════════════"
    log "TEST 4: Stored Procedure Access"
    if test_procedure_access; then
        ((tests_passed++))
    fi
    
    # Test 5: Sample data extraction
    ((total_tests++))
    log "═══════════════════════════════════════"
    log "TEST 5: Sample Data Extraction (Safe)"
    if test_sample_extraction; then
        ((tests_passed++))
    fi
    
    # Summary
    log "═══════════════════════════════════════"
    log "📊 CONNECTION TEST SUMMARY"
    log "  Tests passed: $tests_passed/$total_tests"
    
    if [[ $tests_passed -eq $total_tests ]]; then
        success "🎉 All connection tests passed!"
        log "✅ Ready to proceed with migration"
        return 0
    elif [[ $tests_passed -gt 0 ]]; then
        warn "⚠️  Some tests failed - review issues above"
        log "   You may be able to proceed with limited functionality"
        return 1
    else
        error "❌ All tests failed - check database configuration"
        return 1
    fi
}

# Show help
if [[ "${1:-}" == "--help" ]]; then
    echo "Database Connection Tester"
    echo "========================="
    echo "Tests READ-ONLY access to databases required for migration"
    echo ""
    echo "Usage: $0"
    echo ""
    echo "This script will test:"
    echo "  • Connection to production database (source)"  
    echo "  • Connection to testing database (target)"
    echo "  • Access to stored procedures (wf_meta)"
    echo "  • Sample data extraction (safe read-only)"
    echo ""
    echo "⚠️  IMPORTANT: This script only performs READ operations"
    echo "   No data in production will be modified or deleted"
    exit 0
fi

main "$@"