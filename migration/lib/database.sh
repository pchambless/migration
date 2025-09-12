#!/bin/bash
# Database operations for migration

# Execute stored procedure with error handling
execute_procedure() {
    local proc_name="$1"
    local description="${2:-$proc_name}"
    
    log "Executing procedure: $proc_name"
    log "Description: $description"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run "Would execute: CALL wf_meta.$proc_name();"
        dry_run "Procedure $proc_name would be executed on test server"
        return 0
    fi
    
    start_time=$(date +%s)
    
    # Execute on test server using wf_meta database
    if mysql --defaults-group-suffix=-test -e "CALL wf_meta.$proc_name();" 2>&1; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        success "Procedure $proc_name completed in ${duration}s"
        return 0
    else
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        error "Procedure $proc_name failed after ${duration}s"
        return 1
    fi
}

# Copy table data from production to test (full dump with structure)
copy_table() {
    local table_name="$1"
    local description="${2:-$table_name}"
    
    log "Copying table: $table_name"
    log "Description: Full copy of $description from production to test with structure"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run "Would check source data: SELECT COUNT(*) FROM whatsfresh.$table_name"
        dry_run "Would dump table structure and data from production using mysqldump"
        dry_run "Would import complete table (DROP/CREATE/INSERT) to test server"
        dry_run "Table $table_name copy would be executed"
        return 0
    fi
    
    start_time=$(date +%s)
    
    # Step 1: Get row count from production
    log "Checking source data in production..."
    source_count=$(mysql --defaults-group-suffix=-prod -sN -e "SELECT COUNT(*) FROM whatsfresh.$table_name" 2>/dev/null || echo "0")
    log "Source rows in production: $source_count"
    
    if [[ "$source_count" -eq 0 ]]; then
        warn "No data found in production table $table_name"
        return 0
    fi
    
    # Step 2: Create full dump with structure and data
    log "Creating full dump of $table_name from production..."
    
    # Create temporary dump file
    temp_dump="/tmp/${table_name}_dump_$$.sql"
    
    # Export from production with full structure (includes DROP TABLE, CREATE TABLE, INSERT)
    if mysqldump --defaults-group-suffix=-prod \
        --single-transaction \
        --add-drop-table \
        whatsfresh "$table_name" > "$temp_dump" 2>/dev/null; then
        log "Table structure and data exported from production"
    else
        error "Failed to export table $table_name from production"
        rm -f "$temp_dump"
        return 1
    fi
    
    # Step 3: Import complete table to test server
    log "Importing complete table structure and $source_count rows to test..."
    
    if mysql --defaults-group-suffix=-test whatsfresh < "$temp_dump" 2>/dev/null; then
        log "Complete table imported to test server"
    else
        error "Failed to import table $table_name to test server"
        rm -f "$temp_dump"
        return 1
    fi
    
    # Clean up temp file
    rm -f "$temp_dump"
    
    # Step 4: Verify copy
    target_count=$(mysql --defaults-group-suffix=-test -sN -e "SELECT COUNT(*) FROM whatsfresh.$table_name" 2>/dev/null || echo "0")
    log "Target rows in test: $target_count"
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    if [[ "$source_count" -eq "$target_count" ]]; then
        success "Table $table_name copied successfully: $source_count rows in ${duration}s"
        return 0
    else
        error "Row count mismatch for $table_name: source=$source_count, target=$target_count"
        return 1
    fi
}