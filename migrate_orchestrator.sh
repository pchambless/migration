#!/bin/bash
# Migration Orchestrator
# Handles: Production DB → Data Conversion → Testing DB

set -euo pipefail

# Configuration
CONFIG="./config.json"
LOG_DIR="./logs"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/migration_$TIMESTAMP.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Setup directories
setup_dirs() {
    mkdir -p "$LOG_DIR" "$BACKUP_DIR"
}

# Validate configuration
validate_config() {
    log "Validating configuration..."
    
    if [[ ! -f "$CONFIG" ]]; then
        error "Configuration file $CONFIG not found"
    fi
    
    # Check required fields
    SOURCE_DB=$(jq -r '.source' "$CONFIG" 2>/dev/null) || error "Invalid JSON in config file"
    TARGET_DB=$(jq -r '.target' "$CONFIG" 2>/dev/null) || error "Invalid JSON in config file"
    
    if [[ "$SOURCE_DB" == "null" || "$TARGET_DB" == "null" ]]; then
        error "Source and target databases must be specified in config"
    fi
    
    success "Configuration validated"
}

# Test database connections
test_connections() {
    log "Testing database connections..."
    
    # Test source database
    if ! mysql -e "SELECT 1" "$SOURCE_DB" >/dev/null 2>&1; then
        error "Cannot connect to source database: $SOURCE_DB"
    fi
    
    # Test target database
    if ! mysql -e "SELECT 1" "$TARGET_DB" >/dev/null 2>&1; then
        error "Cannot connect to target database: $TARGET_DB"
    fi
    
    success "Database connections verified"
}

# Create backup of target database
backup_target() {
    log "Creating backup of target database..."
    
    BACKUP_FILE="$BACKUP_DIR/${TARGET_DB}_backup_$TIMESTAMP.sql"
    
    if mysqldump "$TARGET_DB" > "$BACKUP_FILE" 2>/dev/null; then
        success "Backup created: $BACKUP_FILE"
    else
        warn "Backup failed, continuing without backup"
    fi
}

# Extract data from production with selective tables
extract_data() {
    log "Extracting data from production database..."
    
    EXTRACT_FILE="$BACKUP_DIR/${SOURCE_DB}_extract_$TIMESTAMP.sql"
    TABLES=($(jq -r '.tables[]' "$CONFIG"))
    
    if [[ ${#TABLES[@]} -eq 0 ]]; then
        # Full database dump if no specific tables
        mysqldump "$SOURCE_DB" > "$EXTRACT_FILE"
    else
        # Selective table dump
        TABLE_LIST=$(printf " %s" "${TABLES[@]}")
        mysqldump "$SOURCE_DB" $TABLE_LIST > "$EXTRACT_FILE"
    fi
    
    success "Data extracted to: $EXTRACT_FILE"
    echo "$EXTRACT_FILE"
}

# Load data to target database
load_data() {
    local extract_file=$1
    log "Loading data to target database..."
    
    if mysql "$TARGET_DB" < "$extract_file"; then
        success "Data loaded successfully"
    else
        error "Failed to load data to target database"
    fi
}

# Run conversion procedures with enhanced handling
run_conversions() {
    log "Running data conversion procedures..."
    
    # Use the procedure manager for robust execution
    if ./procedure_manager.sh run; then
        success "All conversion procedures completed successfully"
    else
        error "One or more conversion procedures failed"
        log "Check procedure logs for details: $LOG_DIR/procedures_*.log"
        return 1
    fi
}

# Clean up tables in dependency order (respecting foreign key constraints)
cleanup_tables() {
    log "Cleaning up tables in dependency order..."
    
    # Use cleanup_order from config, fallback to legacy tables list
    readarray -t CLEANUP_TABLES < <(jq -r '.cleanup_order[]?' "$CONFIG")
    
    if [[ ${#CLEANUP_TABLES[@]} -eq 0 ]]; then
        warn "No cleanup_order found, using legacy tables list"
        readarray -t CLEANUP_TABLES < <(jq -r '.legacy_config.tables[]?' "$CONFIG")
    fi
    
    if [[ ${#CLEANUP_TABLES[@]} -eq 0 ]]; then
        error "No tables specified for cleanup"
        return 1
    fi
    
    log "Dropping ${#CLEANUP_TABLES[@]} tables in order..."
    
    # Disable foreign key checks temporarily for faster cleanup
    mysql "$TARGET_DB" -e "SET FOREIGN_KEY_CHECKS = 0;" || warn "Could not disable foreign key checks"
    
    for TABLE in "${CLEANUP_TABLES[@]}"; do
        if [[ -n "$TABLE" && "$TABLE" != "null" ]]; then
            log "  Dropping table: whatsfresh.$TABLE"
            mysql "$TARGET_DB" -e "DROP TABLE IF EXISTS whatsfresh.$TABLE;" || warn "Failed to drop $TABLE"
        fi
    done
    
    # Re-enable foreign key checks
    mysql "$TARGET_DB" -e "SET FOREIGN_KEY_CHECKS = 1;" || warn "Could not re-enable foreign key checks"
    
    success "Table cleanup completed"
}

# Validate migration results
validate_migration() {
    log "Validating migration results..."
    
    TABLES=($(jq -r '.tables[]' "$CONFIG"))
    
    for TABLE in "${TABLES[@]}"; do
        # Check if table exists and has data
        COUNT=$(mysql "$TARGET_DB" -sN -e "SELECT COUNT(*) FROM $TABLE" 2>/dev/null || echo "0")
        log "Table $TABLE: $COUNT rows"
    done
    
    success "Migration validation completed"
}

# Main migration process
main() {
    log "🚀 Starting migration orchestration..."
    log "Source: $SOURCE_DB → Target: $TARGET_DB"
    
    setup_dirs
    validate_config
    test_connections
    
    # Validate procedures exist before starting
    log "Pre-validating stored procedures..."
    if ! ./procedure_manager.sh validate; then
        error "Procedure validation failed - check wf_meta database"
        return 1
    fi
    
    # Create backup before making changes
    backup_target
    
    # Extract data from production
    EXTRACT_FILE=$(extract_data)
    
    # Load extracted data
    load_data "$EXTRACT_FILE"
    
    # Clean up old tables
    cleanup_tables
    
    # Run conversion procedures
    run_conversions
    
    # Validate results
    validate_migration
    
    success "🎉 Migration completed successfully!"
    log "Log file: $LOG_FILE"
    log "Extract file: $EXTRACT_FILE"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            log "DRY RUN MODE - No changes will be made"
            # Add dry run logic here
            shift
            ;;
        --config)
            CONFIG="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--config CONFIG_FILE]"
            echo "  --dry-run    : Test run without making changes"
            echo "  --config     : Specify config file (default: ./config.json)"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Run main function
main "$@"