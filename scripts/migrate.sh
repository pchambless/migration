#!/bin/bash

# Migration Management Script for WSL
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

# Check migration status
check_status() {
    log "Checking migration status..."
    
    DB_CMD=$(get_db_connection)
    
    # Create migration table if it doesn't exist
    case "$DB_TYPE" in
        postgresql)
            $DB_CMD -c "CREATE TABLE IF NOT EXISTS $MIGRATION_TABLE (version VARCHAR(255) PRIMARY KEY, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
            $DB_CMD -c "SELECT version, applied_at FROM $MIGRATION_TABLE ORDER BY applied_at;"
            ;;
        mysql)
            $DB_CMD -e "CREATE TABLE IF NOT EXISTS $MIGRATION_TABLE (version VARCHAR(255) PRIMARY KEY, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
            $DB_CMD -e "SELECT version, applied_at FROM $MIGRATION_TABLE ORDER BY applied_at;"
            ;;
        sqlserver)
            $DB_CMD -Q "IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='$MIGRATION_TABLE' AND xtype='U') CREATE TABLE $MIGRATION_TABLE (version VARCHAR(255) PRIMARY KEY, applied_at DATETIME DEFAULT GETDATE());"
            $DB_CMD -Q "SELECT version, applied_at FROM $MIGRATION_TABLE ORDER BY applied_at;"
            ;;
    esac
}

# Apply migrations
migrate_up() {
    log "Applying pending migrations..."
    echo "Migration up functionality would be implemented here"
    echo "This would scan the migrations/ directory and apply pending migrations"
}

# Rollback migrations
migrate_down() {
    log "Rolling back last migration..."
    echo "Migration down functionality would be implemented here"
    echo "This would rollback the most recent migration"
}

# Main script logic
case "${1:-status}" in
    up)
        migrate_up
        ;;
    down)
        migrate_down
        ;;
    status)
        check_status
        ;;
    *)
        echo "Usage: $0 {up|down|status}"
        echo "  up     - Apply pending migrations"
        echo "  down   - Rollback last migration"
        echo "  status - Show migration status"
        exit 1
        ;;
esac