#!/bin/bash

# Migration Tool Setup Script for WSL
set -e

echo "Setting up Migration Tool in WSL environment..."

# Create necessary directories
mkdir -p logs backups

# Check if we're in WSL
if grep -q Microsoft /proc/version; then
    echo "✓ WSL environment detected"
    WSL_MODE=true
else
    echo "ℹ Running in native Linux environment"
    WSL_MODE=false
fi

# Check for required tools
echo "Checking dependencies..."

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "✓ $1 is installed"
    else
        echo "✗ $1 is not installed"
        MISSING_DEPS=true
    fi
}

MISSING_DEPS=false
check_command git
check_command sqlite3

# Database-specific checks
if [ -f "config/database.conf" ]; then
    source config/database.conf
    case "$DB_TYPE" in
        postgresql)
            check_command psql
            ;;
        mysql)
            check_command mysql
            ;;
        sqlserver)
            check_command sqlcmd
            ;;
    esac
fi

if [ "$MISSING_DEPS" = true ]; then
    echo "Please install missing dependencies and run setup again."
    exit 1
fi

# Set up configuration if not exists
if [ ! -f "config/database.conf" ]; then
    echo "Creating database configuration from template..."
    cp config/database.example.conf config/database.conf
    echo "⚠ Please edit config/database.conf with your database settings"
fi

# Make scripts executable
chmod +x scripts/*.sh

# Set up git attributes for proper line endings in WSL
if [ "$WSL_MODE" = true ]; then
    echo "Setting up git attributes for WSL..."
    echo "* text=auto" > .gitattributes
    echo "*.sh text eol=lf" >> .gitattributes
    echo "*.sql text eol=lf" >> .gitattributes
fi

echo "✓ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit config/database.conf with your database settings"
echo "2. Run ./scripts/migrate.sh status to verify connection"
echo "3. Add your migration files to the migrations/ directory"