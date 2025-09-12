#!/bin/bash
# Data Validation Script for Migration
# Compares source and target data to ensure migration integrity

set -euo pipefail

CONFIG="./config.json"
LOG_DIR="./logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
VALIDATION_LOG="$LOG_DIR/validation_$TIMESTAMP.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$VALIDATION_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$VALIDATION_LOG"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$VALIDATION_LOG"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$VALIDATION_LOG"
}

# Setup
mkdir -p "$LOG_DIR"

# Read configuration
SOURCE_DB=$(jq -r '.source' "$CONFIG")
TARGET_DB=$(jq -r '.target' "$CONFIG")
TABLES=($(jq -r '.tables[]' "$CONFIG"))

log "🔍 Starting migration validation..."
log "Source: $SOURCE_DB | Target: $TARGET_DB"

# Pre-migration checks
run_pre_checks() {
    log "Running pre-migration checks..."
    
    readarray -t PRE_CHECKS < <(jq -r '.pre_migration_checks[]?' "$CONFIG")
    
    for CHECK in "${PRE_CHECKS[@]}"; do
        if [[ -n "$CHECK" && "$CHECK" != "null" ]]; then
            log "Executing: $CHECK"
            mysql "$SOURCE_DB" -e "$CHECK" | tee -a "$VALIDATION_LOG"
        fi
    done
}

# Post-migration validation
run_post_checks() {
    log "Running post-migration validation..."
    
    readarray -t POST_CHECKS < <(jq -r '.post_migration_validation[]?' "$CONFIG")
    
    for CHECK in "${POST_CHECKS[@]}"; do
        if [[ -n "$CHECK" && "$CHECK" != "null" ]]; then
            log "Executing: $CHECK"
            mysql "$TARGET_DB" -e "$CHECK" | tee -a "$VALIDATION_LOG"
        fi
    done
}

# Compare row counts between source and target
compare_row_counts() {
    log "Comparing row counts between databases..."
    
    local all_match=true
    
    for TABLE in "${TABLES[@]}"; do
        log "Checking table: $TABLE"
        
        # Get source count
        SOURCE_COUNT=$(mysql "$SOURCE_DB" -sN -e "SELECT COUNT(*) FROM $TABLE" 2>/dev/null || echo "0")
        
        # Get target count
        TARGET_COUNT=$(mysql "$TARGET_DB" -sN -e "SELECT COUNT(*) FROM $TABLE" 2>/dev/null || echo "0")
        
        log "  Source: $SOURCE_COUNT rows | Target: $TARGET_COUNT rows"
        
        if [[ "$SOURCE_COUNT" == "$TARGET_COUNT" ]]; then
            success "  ✓ Row counts match for $TABLE"
        else
            error "  ✗ Row count mismatch for $TABLE"
            all_match=false
        fi
    done
    
    if [[ "$all_match" == true ]]; then
        success "All table row counts match!"
    else
        warn "Some table row counts don't match - review conversion procedures"
    fi
}

# Check for data integrity issues
check_data_integrity() {
    log "Checking data integrity..."
    
    for TABLE in "${TABLES[@]}"; do
        log "Integrity check for $TABLE:"
        
        # Check for NULL values in key fields (customize as needed)
        NULL_COUNT=$(mysql "$TARGET_DB" -sN -e "SELECT COUNT(*) FROM $TABLE WHERE id IS NULL" 2>/dev/null || echo "0")
        
        if [[ "$NULL_COUNT" -gt 0 ]]; then
            warn "  Found $NULL_COUNT NULL id values in $TABLE"
        else
            success "  No NULL id values in $TABLE"
        fi
        
        # Check for duplicate entries
        DUPLICATE_COUNT=$(mysql "$TARGET_DB" -sN -e "SELECT COUNT(*) - COUNT(DISTINCT id) FROM $TABLE" 2>/dev/null || echo "0")
        
        if [[ "$DUPLICATE_COUNT" -gt 0 ]]; then
            warn "  Found $DUPLICATE_COUNT duplicate entries in $TABLE"
        else
            success "  No duplicate entries in $TABLE"
        fi
    done
}

# Sample data comparison (first 5 rows)
compare_sample_data() {
    log "Comparing sample data (first 5 rows)..."
    
    for TABLE in "${TABLES[@]}"; do
        log "Sample data for $TABLE:"
        
        log "  Source sample:"
        mysql "$SOURCE_DB" -e "SELECT * FROM $TABLE LIMIT 5" | tee -a "$VALIDATION_LOG"
        
        log "  Target sample:"
        mysql "$TARGET_DB" -e "SELECT * FROM $TABLE LIMIT 5" | tee -a "$VALIDATION_LOG"
        
        echo "---" >> "$VALIDATION_LOG"
    done
}

# Generate validation report
generate_report() {
    local report_file="$LOG_DIR/migration_report_$TIMESTAMP.txt"
    
    {
        echo "Migration Validation Report"
        echo "=========================="
        echo "Date: $(date)"
        echo "Source Database: $SOURCE_DB"
        echo "Target Database: $TARGET_DB"
        echo "Tables Migrated: ${TABLES[*]}"
        echo ""
        echo "Validation Log:"
        echo "==============="
        cat "$VALIDATION_LOG"
    } > "$report_file"
    
    success "Validation report generated: $report_file"
}

# Main validation process
main() {
    case "${1:-full}" in
        "pre")
            run_pre_checks
            ;;
        "post")
            run_post_checks
            ;;
        "counts")
            compare_row_counts
            ;;
        "integrity")
            check_data_integrity
            ;;
        "sample")
            compare_sample_data
            ;;
        "full"|*)
            run_pre_checks
            run_post_checks
            compare_row_counts
            check_data_integrity
            compare_sample_data
            generate_report
            ;;
    esac
    
    success "Validation completed!"
}

# Show usage
if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [pre|post|counts|integrity|sample|full]"
    echo "  pre       : Run pre-migration checks only"
    echo "  post      : Run post-migration validation only"
    echo "  counts    : Compare row counts only"
    echo "  integrity : Check data integrity only"
    echo "  sample    : Compare sample data only"
    echo "  full      : Run all validations (default)"
    exit 0
fi

main "$@"