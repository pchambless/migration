#!/bin/bash

# WSL Environment Test Script
# This script validates that the migration tool is properly set up for WSL

set -e

echo "=== Migration Tool WSL Environment Test ==="
echo ""

# Test 1: Check if we're in WSL
echo "1. WSL Environment Detection:"
if grep -q Microsoft /proc/version; then
    echo "   ✓ Running in WSL environment"
    WSL_VERSION=$(grep -oP 'Microsoft.*WSL\K\d+' /proc/version || echo "1")
    echo "   ✓ Detected WSL version: $WSL_VERSION"
else
    echo "   ℹ Running in native Linux environment (this is fine)"
fi
echo ""

# Test 2: File permissions
echo "2. Script Permissions:"
for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        echo "   ✓ $script is executable"
    else
        echo "   ✗ $script is not executable"
        chmod +x "$script"
        echo "   → Fixed: Made $script executable"
    fi
done
echo ""

# Test 3: Line endings
echo "3. Line Endings Check:"
if command -v file >/dev/null 2>&1; then
    for script in scripts/*.sh; do
        if file "$script" | grep -q "CRLF"; then
            echo "   ✗ $script has Windows line endings (CRLF)"
            if command -v dos2unix >/dev/null 2>&1; then
                dos2unix "$script"
                echo "   → Fixed: Converted to Unix line endings"
            else
                echo "   → Please install dos2unix to fix line endings"
            fi
        else
            echo "   ✓ $script has Unix line endings"
        fi
    done
else
    echo "   ℹ 'file' command not available, skipping line ending check"
fi
echo ""

# Test 4: Configuration files
echo "4. Configuration Files:"
if [ -f "config/database.conf" ]; then
    echo "   ✓ Database configuration exists"
    if grep -q "your_password_here" config/database.conf; then
        echo "   ⚠ Database configuration still has default values"
        echo "     → Edit config/database.conf with your database settings"
    else
        echo "   ✓ Database configuration appears to be customized"
    fi
else
    echo "   ✗ Database configuration missing"
    echo "     → Run ./scripts/setup.sh to create configuration"
fi

if [ -f "config/migration.conf" ]; then
    echo "   ✓ Migration configuration exists"
else
    echo "   ✗ Migration configuration missing"
fi
echo ""

# Test 5: Directory structure
echo "5. Directory Structure:"
REQUIRED_DIRS=("migrations" "config" "scripts" "db/views" "db/schemas" "docs")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "   ✓ $dir/ exists"
    else
        echo "   ✗ $dir/ missing"
        mkdir -p "$dir"
        echo "   → Created: $dir/"
    fi
done
echo ""

# Test 6: Dependencies
echo "6. Required Dependencies:"
REQUIRED_COMMANDS=("git" "bash")
OPTIONAL_COMMANDS=("psql" "mysql" "sqlite3" "dos2unix")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "   ✓ $cmd is installed"
    else
        echo "   ✗ $cmd is missing (required)"
    fi
done

echo ""
echo "   Optional database tools:"
for cmd in "${OPTIONAL_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "   ✓ $cmd is available"
    else
        echo "   - $cmd not found (install if needed for your database)"
    fi
done
echo ""

# Test 7: Git configuration
echo "7. Git Configuration:"
if [ -f ".gitattributes" ]; then
    echo "   ✓ .gitattributes exists for line ending management"
else
    echo "   ✗ .gitattributes missing"
fi

if [ -f ".gitignore" ]; then
    echo "   ✓ .gitignore exists"
else
    echo "   ✗ .gitignore missing"
fi
echo ""

# Test 8: Quick functionality test
echo "8. Basic Functionality Test:"
if ./scripts/migrate.sh --help >/dev/null 2>&1 || ./scripts/migrate.sh 2>&1 | grep -q "Usage:"; then
    echo "   ✓ Migration script responds correctly"
else
    echo "   ⚠ Migration script may have issues (this is normal without database connection)"
fi

if [ -f "migrations/20241201_001_create_users_table.sql" ]; then
    echo "   ✓ Example migration file exists"
else
    echo "   - No example migration files found"
fi

if [ -f "db/views/active_users.sql" ]; then
    echo "   ✓ Example view file exists"
else
    echo "   - No example view files found"
fi
echo ""

echo "=== WSL Environment Test Complete ==="
echo ""
echo "Next steps:"
echo "1. Edit config/database.conf with your database settings"
echo "2. Test database connection: ./scripts/migrate.sh status"
echo "3. Add your migration files to migrations/"
echo "4. Run migrations: ./scripts/migrate.sh up"