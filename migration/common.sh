#!/bin/bash
# Common functions and configuration for migration steps

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration  
CONFIG="config.json"
LOG_DIR="logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Port assignments
PROD_PORT=13306
TEST_PORT=13307

# Dry run mode (set by --dry-run flag)
DRY_RUN=${DRY_RUN:-false}

# Create log directory
mkdir -p "$LOG_DIR"

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
}

dry_run() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $1" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
}

# Step logging
log_step_start() {
    local step_name="$1"
    echo | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
    echo "=================================================================" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
    log "🚀 Starting: $step_name"
    echo "=================================================================" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
}

log_step_success() {
    local step_name="$1"
    local message="$2"
    echo "=================================================================" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
    success "✅ Completed: $step_name - $message"
    echo "=================================================================" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
    echo | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
}

log_step_error() {
    local step_name="$1"
    local message="$2"
    echo "=================================================================" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
    error "❌ Failed: $step_name - $message"
    echo "=================================================================" | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
    echo | tee -a "$LOG_DIR/migration_$TIMESTAMP.log"
}

# Check if tunnels are active
check_tunnels() {
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run "Would check tunnel connectivity on ports $PROD_PORT and $TEST_PORT"
        dry_run "Tunnel connectivity check bypassed in dry-run mode"
        return 0
    fi
    
    log "Checking tunnel status..."
    
    if ! nc -z localhost "$PROD_PORT" 2>/dev/null; then
        error "Production tunnel not accessible on port $PROD_PORT"
        error "Run: ./session/start.sh prodServer"
        return 1
    fi
    
    if ! nc -z localhost "$TEST_PORT" 2>/dev/null; then
        error "Test server tunnel not accessible on port $TEST_PORT" 
        error "Run: ./session/start.sh testServer"
        return 1
    fi
    
    success "Both tunnels are accessible"
}

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
    if mysql -h localhost -P "$TEST_PORT" -u root -p -e "CALL wf_meta.$proc_name();" 2>&1; then
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

# Copy table data from production to test (straight copy, no conversions)
copy_table() {
    local table_name="$1"
    local description="${2:-$table_name}"
    
    log "Copying table: $table_name"
    log "Description: Straight copy of $description from production to test"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run "Would check source data: SELECT COUNT(*) FROM whatsfresh.$table_name"
        dry_run "Would clear target data: DELETE FROM whatsfresh.$table_name"  
        dry_run "Would copy data from production to test using mysqldump"
        dry_run "Table $table_name copy would be executed"
        return 0
    fi
    
    start_time=$(date +%s)
    
    # Step 1: Get row count from production
    log "Checking source data in production..."
    source_count=$(mysql -h localhost -P "$PROD_PORT" -u paul -p -sN -e "SELECT COUNT(*) FROM whatsfresh.$table_name" 2>/dev/null || echo "0")
    log "Source rows in production: $source_count"
    
    if [[ "$source_count" -eq 0 ]]; then
        warn "No data found in production table $table_name"
        return 0
    fi
    
    # Step 2: Clear existing data in test
    log "Clearing existing data in test server..."
    mysql -h localhost -P "$TEST_PORT" -u root -p -e "DELETE FROM whatsfresh.$table_name;" || {
        error "Failed to clear existing data from $table_name"
        return 1
    }
    
    # Step 3: Copy data using mysqldump and mysql
    log "Copying $source_count rows from production to test..."
    
    # Create temporary dump file
    temp_dump="/tmp/${table_name}_dump_$$.sql"
    
    # Export from production
    if mysqldump -h localhost -P "$PROD_PORT" -u paul -p --single-transaction --no-create-info whatsfresh "$table_name" > "$temp_dump" 2>/dev/null; then
        log "Data exported from production"
    else
        error "Failed to export data from production table $table_name"
        rm -f "$temp_dump"
        return 1
    fi
    
    # Import to test server
    if mysql -h localhost -P "$TEST_PORT" -u root -p whatsfresh < "$temp_dump" 2>/dev/null; then
        log "Data imported to test server"
    else
        error "Failed to import data to test table $table_name"
        rm -f "$temp_dump"
        return 1
    fi
    
    # Clean up temp file
    rm -f "$temp_dump"
    
    # Step 4: Verify copy
    target_count=$(mysql -h localhost -P "$TEST_PORT" -u root -p -sN -e "SELECT COUNT(*) FROM whatsfresh.$table_name" 2>/dev/null || echo "0")
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