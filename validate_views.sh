#!/bin/bash
# View Validation Script
# Tests all views in a database to identify broken ones
# Usage: ./validate_views.sh <database_name>

set -uo pipefail

# Source common functions
source migration/lib/common.sh

# Test-only tunnel check
check_test_tunnel() {
    log "Checking test tunnel connectivity..."
    if ! nc -z localhost "$TEST_PORT" 2>/dev/null; then
        warn "Test tunnel not accessible on port $TEST_PORT"
        log "Starting test tunnel..."
        if ./tunnel_manager_v2.sh start-test; then
            log "Waiting 3 seconds for tunnel to establish..."
            sleep 3
            if nc -z localhost "$TEST_PORT" 2>/dev/null; then
                success "Test tunnel started successfully"
            else
                error "Failed to establish test tunnel connection"
                return 1
            fi
        else
            error "Failed to start test tunnel"
            return 1
        fi
    else
        success "Test tunnel already running"
    fi
}

# Check arguments
if [[ $# -eq 0 ]]; then
    error "Database name required"
    echo "Usage: $0 <database_name>"
    echo "Example: $0 whatsfresh"
    exit 1
fi

DATABASE="$1"
TIMESTAMP=$(date '+%y-%m-%d %H:%M')

# Create view-validation folder if it doesn't exist
VIEW_VALIDATION_DIR="view-validation"
mkdir -p "$VIEW_VALIDATION_DIR"

REPORT_FILE="$VIEW_VALIDATION_DIR/${TIMESTAMP} ${DATABASE}.log"

log "🔍 Starting view validation for database '$DATABASE'"
log "📄 Report will be saved as: ${REPORT_FILE}"

# Ensure test tunnel is running
check_test_tunnel || exit 1

# Get all views
log "Getting list of views..."
VIEWS=$(mysql --defaults-group-suffix=-test -sN -e "
    SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.VIEWS 
    WHERE TABLE_SCHEMA = '$DATABASE' 
    ORDER BY TABLE_NAME;
" 2>/dev/null)

if [[ -z "$VIEWS" ]]; then
    warn "No views found in database '$DATABASE'"
    exit 0
fi

VIEW_COUNT=$(echo "$VIEWS" | wc -l)
log "Found $VIEW_COUNT views to test"

# Initialize counters
PASSED=0
FAILED=0
FAILED_VIEWS=()

echo
echo "================================================================="
echo "Testing Views in '$DATABASE'"
echo "================================================================="

# Test each view
while IFS= read -r view; do
    printf "Testing %-30s..." "$view"
    
    start_time=$(date +%s%N)
    
    if mysql --defaults-group-suffix=-test -e "SELECT COUNT(*) FROM \`$DATABASE\`.\`$view\` LIMIT 1;" >/dev/null 2>&1; then
        end_time=$(date +%s%N)
        duration=$(( (end_time - start_time) / 1000000 ))
        
        printf " ✅ OK (${duration}ms)\n"
        ((PASSED++))
        echo "✅ $view - OK (${duration}ms)" >> "$REPORT_FILE"
    else
        printf " ❌ FAILED\n"
        ((FAILED++))
        FAILED_VIEWS+=("$view")
        
        # Get detailed error
        error_msg=$(mysql --defaults-group-suffix=-test -e "SELECT COUNT(*) FROM \`$DATABASE\`.\`$view\` LIMIT 1;" 2>&1 | tail -1)
        
        # Format and display error on next line, wrapped
        printf "    └─ Error: "
        echo "$error_msg" | fold -w 65 -s | sed '2,$s/^/               /'
        echo
        
        # Write formatted error to log file too
        echo "❌ $view - FAILED:" >> "$REPORT_FILE"
        echo "$error_msg" | fold -w 75 -s | sed 's/^/    /' >> "$REPORT_FILE"
        echo >> "$REPORT_FILE"
    fi
    
done <<< "$VIEWS"

echo
echo "================================================================="
echo "VALIDATION SUMMARY"
echo "================================================================="

if [[ $FAILED -eq 0 ]]; then
    success "All $VIEW_COUNT views are valid! ✨"
else
    error "Found $FAILED broken views out of $VIEW_COUNT total:"
    echo
    for failed_view in "${FAILED_VIEWS[@]}"; do
        # Get the error for this view from the log file
        error_msg=$(grep "❌ $failed_view - FAILED:" "$REPORT_FILE" | sed "s/❌ $failed_view - FAILED: //")
        
        echo "❌ $failed_view - FAILED:"
        echo "$error_msg" | fold -w 75 -s | sed 's/^/    /'
        echo
    done
fi

success "$PASSED views passed"
[[ $FAILED -gt 0 ]] && error "$FAILED views failed"

echo
log "📄 Detailed report saved: $REPORT_FILE"

# Exit code reflects health
exit $FAILED