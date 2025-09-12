#!/bin/bash
# Stored Procedure Management for Migration
# Handles validation, execution, and monitoring of conversion procedures

set -euo pipefail

CONFIG="./config.json"
LOG_DIR="./logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PROC_LOG="$LOG_DIR/procedures_$TIMESTAMP.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$PROC_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$PROC_LOG"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$PROC_LOG"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$PROC_LOG"
}

# Setup
mkdir -p "$LOG_DIR"

# Read configuration
SOURCE_DB=$(jq -r '.source' "$CONFIG")
TARGET_DB=$(jq -r '.target' "$CONFIG")
META_DB="wf_meta"

# List all stored procedures in wf_meta
list_procedures() {
    log "📋 Listing stored procedures in $META_DB..."
    
    mysql "$META_DB" -e "
        SELECT 
            ROUTINE_NAME as 'Procedure Name',
            ROUTINE_TYPE as 'Type',
            CREATED as 'Created Date',
            LAST_ALTERED as 'Last Modified'
        FROM information_schema.ROUTINES 
        WHERE ROUTINE_SCHEMA = '$META_DB' 
        AND ROUTINE_TYPE = 'PROCEDURE'
        ORDER BY ROUTINE_NAME
    " | tee -a "$PROC_LOG"
}

# Validate procedure exists and is callable
validate_procedure() {
    local proc_name=$1
    log "🔍 Validating procedure: $proc_name"
    
    # Check if procedure exists
    local exists=$(mysql "$META_DB" -sN -e "
        SELECT COUNT(*) 
        FROM information_schema.ROUTINES 
        WHERE ROUTINE_SCHEMA = '$META_DB' 
        AND ROUTINE_NAME = '$proc_name' 
        AND ROUTINE_TYPE = 'PROCEDURE'
    ")
    
    if [[ "$exists" -eq 0 ]]; then
        error "Procedure $proc_name not found in $META_DB"
        return 1
    fi
    
    success "Procedure $proc_name exists and is valid"
    return 0
}

# Get procedure definition
show_procedure() {
    local proc_name=$1
    log "📝 Showing definition for procedure: $proc_name"
    
    mysql "$META_DB" -e "SHOW CREATE PROCEDURE $proc_name\\G" | tee -a "$PROC_LOG"
}

# Execute procedure with error handling and timing
execute_procedure() {
    local proc_name=$1
    local start_time=$(date +%s)
    
    log "🚀 Executing procedure: $proc_name"
    
    # Enable SQL logging for this procedure
    mysql "$TARGET_DB" -e "SET SESSION general_log = ON;" 2>/dev/null || true
    
    # Execute the procedure with error capture
    if timeout 3600 mysql "$TARGET_DB" -e "CALL $META_DB.$proc_name();" 2>&1 | tee -a "$PROC_LOG"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Procedure $proc_name completed successfully in ${duration}s"
        
        # Log affected rows if possible
        local affected=$(mysql "$TARGET_DB" -sN -e "SELECT ROW_COUNT();" 2>/dev/null || echo "unknown")
        log "Affected rows: $affected"
        
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error "Procedure $proc_name failed after ${duration}s"
        return 1
    fi
}

# Check procedure execution history
check_execution_history() {
    log "📊 Checking procedure execution history..."
    
    # Check if general log is available
    local log_enabled=$(mysql "$TARGET_DB" -sN -e "SELECT @@global.general_log;" 2>/dev/null || echo "OFF")
    
    if [[ "$log_enabled" == "ON" ]]; then
        log "General log is enabled - recent procedure calls:"
        mysql "$TARGET_DB" -e "
            SELECT event_time, user_host, thread_id, command_type, argument 
            FROM mysql.general_log 
            WHERE argument LIKE '%CALL%' 
            ORDER BY event_time DESC 
            LIMIT 10
        " 2>/dev/null || warn "Could not access general log"
    else
        warn "General log is disabled - cannot show execution history"
    fi
}

# Validate procedure results
validate_procedure_results() {
    local proc_name=$1
    log "✅ Validating results from procedure: $proc_name"
    
    # Based on your example procedure, check the created table
    case "$proc_name" in
        "convertIngredientBatches")
            local table="ingredient_batches"
            local count=$(mysql "$TARGET_DB" -sN -e "SELECT COUNT(*) FROM whatsfresh.$table" 2>/dev/null || echo "0")
            log "Table whatsfresh.$table has $count rows"
            
            # Check if active column was added
            local active_col=$(mysql "$TARGET_DB" -sN -e "
                SELECT COUNT(*) 
                FROM information_schema.COLUMNS 
                WHERE TABLE_SCHEMA = 'whatsfresh' 
                AND TABLE_NAME = '$table' 
                AND COLUMN_NAME = 'active'
            " 2>/dev/null || echo "0")
            
            if [[ "$active_col" -eq 1 ]]; then
                success "Active column successfully added to $table"
            else
                warn "Active column not found in $table"
            fi
            ;;
        "convertProdBtch")
            log "Validating product batch conversion results..."
            # Add specific validation for product batches
            ;;
        *)
            log "Generic validation for procedure: $proc_name"
            ;;
    esac
}

# Run all procedures from config with enhanced error handling
run_all_procedures() {
    log "🔄 Running all configured procedures in dependency order..."
    
    # Use procedures_ordered first, fallback to legacy procedures
    readarray -t PROCS < <(jq -r '.procedures_ordered[]?' "$CONFIG")
    
    if [[ ${#PROCS[@]} -eq 0 ]]; then
        warn "No procedures_ordered found, using legacy procedures list"
        readarray -t PROCS < <(jq -r '.legacy_config.procedures[]?' "$CONFIG")
    fi
    
    if [[ ${#PROCS[@]} -eq 0 ]]; then
        error "No procedures specified in configuration"
        return 1
    fi
    
    local failed_procs=()
    local success_count=0
    local total_start_time=$(date +%s)
    
    log "Executing ${#PROCS[@]} procedures in order..."
    
    for i in "${!PROCS[@]}"; do
        local PROC="${PROCS[i]}"
        local step_num=$((i + 1))
        
        log "===========================================" 
        log "Step $step_num/${#PROCS[@]}: Processing procedure $PROC"
        
        # Validate procedure exists
        if ! validate_procedure "$PROC"; then
            failed_procs+=("$PROC")
            continue
        fi
        
        # Execute procedure with enhanced timing
        local proc_start_time=$(date +%s)
        if execute_procedure "$PROC"; then
            local proc_end_time=$(date +%s)
            local proc_duration=$((proc_end_time - proc_start_time))
            
            validate_procedure_results "$PROC"
            ((success_count++))
            
            success "Step $step_num completed in ${proc_duration}s"
            
            # Brief pause between procedures to allow logging to catch up
            sleep 1
        else
            failed_procs+=("$PROC")
            error "Step $step_num failed - stopping migration"
            break  # Stop on first failure for dependency reasons
        fi
        
        log "===========================================" 
    done
    
    local total_end_time=$(date +%s)
    local total_duration=$((total_end_time - total_start_time))
    
    # Summary
    log "📈 Migration Execution Summary:"
    log "  Total procedures: ${#PROCS[@]}"
    log "  Successful: $success_count"
    log "  Failed: ${#failed_procs[@]}"
    log "  Total time: ${total_duration}s"
    
    if [[ ${#failed_procs[@]} -gt 0 ]]; then
        error "Failed procedures: ${failed_procs[*]}"
        log "Migration stopped at first failure due to dependencies"
        return 1
    else
        success "All procedures executed successfully in ${total_duration}s!"
        return 0
    fi
}

# Backup procedure definitions
backup_procedures() {
    local backup_file="$LOG_DIR/procedures_backup_$TIMESTAMP.sql"
    log "💾 Backing up procedure definitions to: $backup_file"
    
    readarray -t PROCS < <(jq -r '.procedures[]' "$CONFIG")
    
    {
        echo "-- Procedure definitions backup created: $(date)"
        echo "-- Use this file to restore procedures if needed"
        echo ""
        
        for PROC in "${PROCS[@]}"; do
            echo "-- =========================================="
            echo "-- Procedure: $PROC" 
            echo "-- =========================================="
            mysql "$META_DB" -e "SHOW CREATE PROCEDURE $PROC\\G" | grep -A1000 "Create Procedure:"
            echo ""
        done
    } > "$backup_file"
    
    success "Procedure definitions backed up to: $backup_file"
}

# Main function
main() {
    case "${1:-run}" in
        "list"|"ls")
            list_procedures
            ;;
        "validate")
            if [[ -n "${2:-}" ]]; then
                validate_procedure "$2"
            else
                readarray -t PROCS < <(jq -r '.procedures[]' "$CONFIG")
                for PROC in "${PROCS[@]}"; do
                    validate_procedure "$PROC"
                done
            fi
            ;;
        "show")
            if [[ -n "${2:-}" ]]; then
                show_procedure "$2"
            else
                error "Usage: $0 show <procedure_name>"
            fi
            ;;
        "execute")
            if [[ -n "${2:-}" ]]; then
                execute_procedure "$2"
            else
                error "Usage: $0 execute <procedure_name>"
            fi
            ;;
        "history")
            check_execution_history
            ;;
        "backup")
            backup_procedures
            ;;
        "run"|*)
            run_all_procedures
            ;;
    esac
}

# Show usage
if [[ "${1:-}" == "--help" ]]; then
    echo "Stored Procedure Manager for Migration"
    echo "======================================"
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list              : List all procedures in wf_meta"
    echo "  validate [proc]   : Validate procedure exists (all if no proc specified)"
    echo "  show <proc>       : Show procedure definition"
    echo "  execute <proc>    : Execute specific procedure"
    echo "  history           : Show recent procedure execution history"
    echo "  backup            : Backup all procedure definitions"
    echo "  run               : Run all procedures from config (default)"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 validate convertIngredientBatches"
    echo "  $0 execute convertIngredientBatches"
    echo "  $0 run"
    exit 0
fi

main "$@"