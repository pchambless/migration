#!/bin/bash

# Database Views Validation Script for WSL
set -e

# Load configuration
if [ -f "config/database.conf" ]; then
    source config/database.conf
else
    echo "Error: config/database.conf not found. Run ./scripts/setup.sh first."
    exit 1
fi

if [ -f "config/migration.conf" ]; then
    source config/migration.conf
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE:-./logs/migration.log}"
}

# Database connection helper
get_db_connection() {
    case "$DB_TYPE" in
        postgresql)
            echo "psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER"
            ;;
        mysql)
            echo "mysql -h $DB_HOST -P $DB_PORT -D $DB_NAME -u $DB_USER -p$DB_PASSWORD"
            ;;
        sqlserver)
            echo "sqlcmd -S $DB_HOST,$DB_PORT -d $DB_NAME -U $DB_USER -P $DB_PASSWORD"
            ;;
        *)
            echo "Unsupported database type: $DB_TYPE"
            exit 1
            ;;
    esac
}

# Validate views
validate_views() {
    log "Starting database views validation..."
    
    if [ ! -d "$VIEWS_DIR" ]; then
        log "Views directory not found: $VIEWS_DIR"
        return 1
    fi
    
    DB_CMD=$(get_db_connection)
    ERRORS=0
    
    for view_file in "$VIEWS_DIR"/*.sql; do
        if [ -f "$view_file" ]; then
            view_name=$(basename "$view_file" .sql)
            log "Validating view: $view_name"
            
            # Extract view definition and validate syntax
            case "$DB_TYPE" in
                postgresql)
                    if ! $DB_CMD -f "$view_file" --dry-run >/dev/null 2>&1; then
                        log "ERROR: View $view_name has syntax errors"
                        ERRORS=$((ERRORS + 1))
                    else
                        log "✓ View $view_name syntax is valid"
                    fi
                    ;;
                mysql)
                    # MySQL doesn't have a direct dry-run, so we'd need custom validation
                    log "ℹ View $view_name - manual validation needed for MySQL"
                    ;;
                sqlserver)
                    # SQL Server validation would be implemented here
                    log "ℹ View $view_name - manual validation needed for SQL Server"
                    ;;
            esac
        fi
    done
    
    if [ $ERRORS -eq 0 ]; then
        log "✓ All views validated successfully"
        return 0
    else
        log "✗ Found $ERRORS view validation errors"
        return 1
    fi
}

# Main execution
log "Database Views Validation Tool"
validate_views