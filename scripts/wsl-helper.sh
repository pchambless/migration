#!/bin/bash

# WSL Helper Script for Migration Tool
# Provides common utilities for WSL development

set -e

show_help() {
    echo "WSL Helper Script for Migration Tool"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  host-ip        Get Windows host IP for database connections"
    echo "  fix-perms      Fix file permissions for WSL"
    echo "  fix-lineend    Fix line endings for all scripts"
    echo "  check-db       Test database connectivity"
    echo "  setup-env      Set up environment variables"
    echo "  test           Run WSL environment test"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 host-ip     # Get IP to use for DB_HOST in config"
    echo "  $0 fix-perms   # Fix permissions after cloning from Windows"
    echo "  $0 check-db    # Test if database is reachable"
}

get_host_ip() {
    echo "Getting Windows host IP for database connections..."
    
    if grep -q Microsoft /proc/version; then
        # We're in WSL
        if [ -f /etc/resolv.conf ]; then
            HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)
            echo "Windows host IP: $HOST_IP"
            echo ""
            echo "To use this IP for database connections:"
            echo "1. Edit config/database.conf"
            echo "2. Set DB_HOST=$HOST_IP"
            echo "3. Ensure Windows firewall allows connections from WSL"
        else
            echo "Could not determine host IP"
        fi
    else
        echo "Not running in WSL - use localhost for database connections"
    fi
}

fix_permissions() {
    echo "Fixing file permissions for WSL..."
    
    # Make scripts executable
    chmod +x scripts/*.sh
    echo "✓ Scripts are now executable"
    
    # Ensure config files are readable but not executable
    chmod 644 config/*.conf
    echo "✓ Configuration files have correct permissions"
    
    # Ensure directories have correct permissions
    find . -type d -exec chmod 755 {} \;
    echo "✓ Directory permissions fixed"
    
    echo "File permissions have been corrected for WSL"
}

fix_line_endings() {
    echo "Fixing line endings for WSL compatibility..."
    
    if command -v dos2unix >/dev/null 2>&1; then
        # Fix shell scripts
        dos2unix scripts/*.sh 2>/dev/null || true
        echo "✓ Shell scripts converted to Unix line endings"
        
        # Fix SQL files
        find migrations db -name "*.sql" -exec dos2unix {} \; 2>/dev/null || true
        echo "✓ SQL files converted to Unix line endings"
        
        # Fix config files
        dos2unix config/*.conf 2>/dev/null || true
        echo "✓ Configuration files converted to Unix line endings"
        
        echo "Line endings have been fixed"
    else
        echo "dos2unix not found. Install it with:"
        echo "  sudo apt-get install dos2unix  # Ubuntu/Debian"
        echo "  sudo yum install dos2unix      # RHEL/CentOS"
        exit 1
    fi
}

check_database() {
    echo "Testing database connectivity..."
    
    if [ ! -f "config/database.conf" ]; then
        echo "✗ config/database.conf not found"
        echo "Run ./scripts/setup.sh first"
        exit 1
    fi
    
    source config/database.conf
    
    echo "Database type: $DB_TYPE"
    echo "Host: $DB_HOST"
    echo "Port: $DB_PORT"
    echo "Database: $DB_NAME"
    echo ""
    
    case "$DB_TYPE" in
        postgresql)
            echo "Testing PostgreSQL connection..."
            if command -v psql >/dev/null 2>&1; then
                if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
                    echo "✓ PostgreSQL connection successful"
                else
                    echo "✗ PostgreSQL connection failed"
                    echo "Check your configuration and ensure the database server is running"
                fi
            else
                echo "✗ psql command not found. Install PostgreSQL client tools."
            fi
            ;;
        mysql)
            echo "Testing MySQL connection..."
            if command -v mysql >/dev/null 2>&1; then
                if mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
                    echo "✓ MySQL connection successful"
                else
                    echo "✗ MySQL connection failed"
                    echo "Check your configuration and ensure the database server is running"
                fi
            else
                echo "✗ mysql command not found. Install MySQL client tools."
            fi
            ;;
        *)
            echo "Database type '$DB_TYPE' not supported by this test"
            ;;
    esac
}

setup_environment() {
    echo "Setting up environment variables for WSL..."
    
    MIGRATION_HOME=$(pwd)
    
    echo "Add these lines to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "# Migration Tool Environment"
    echo "export MIGRATION_HOME=\"$MIGRATION_HOME\""
    echo "export PATH=\"\$PATH:\$MIGRATION_HOME/scripts\""
    echo ""
    echo "After adding, run: source ~/.bashrc"
    echo ""
    echo "This will allow you to run migration scripts from anywhere:"
    echo "  migrate.sh status"
    echo "  validate-views.sh"
}

# Main script logic
case "${1:-help}" in
    host-ip|hostip)
        get_host_ip
        ;;
    fix-perms|perms)
        fix_permissions
        ;;
    fix-lineend|lineend)
        fix_line_endings
        ;;
    check-db|db)
        check_database
        ;;
    setup-env|env)
        setup_environment
        ;;
    test)
        ./scripts/test-wsl.sh
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac