#!/bin/bash
# MySQL Connection Setup Helper

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log "🔧 MySQL Connection Setup Helper"

# Check if MySQL client is installed
check_mysql_client() {
    log "Checking MySQL client installation..."
    
    if command -v mysql >/dev/null 2>&1; then
        local version=$(mysql --version 2>/dev/null || echo "unknown")
        success "✓ MySQL client is installed: $version"
        return 0
    else
        error "✗ MySQL client not found"
        log "Install with: sudo apt-get update && sudo apt-get install mysql-client"
        return 1
    fi
}

# Check network connectivity
check_network() {
    log "Checking network connectivity..."
    
    # Test localhost (SSH tunnel endpoint)
    if nc -z localhost 3306 2>/dev/null; then
        success "✓ Port 3306 is open on localhost (SSH tunnel likely active)"
        return 0
    else
        warn "⚠ Port 3306 not accessible on localhost"
        log "  This suggests SSH tunnel may not be active or using different port"
        return 1
    fi
}

# Check SSH tunnel status
check_ssh_tunnel() {
    log "Checking SSH tunnel status..."
    
    # Look for SSH processes
    local ssh_count=$(ps aux | grep -E "ssh.*3306" | grep -v grep | wc -l)
    
    if [[ $ssh_count -gt 0 ]]; then
        success "✓ SSH tunnel processes found:"
        ps aux | grep -E "ssh.*3306" | grep -v grep || true
    else
        warn "⚠ No SSH tunnel processes found"
        log "  Your MobaXterm tunnel may be configured differently"
    fi
}

# Test basic MySQL connection
test_mysql_connection() {
    log "Testing MySQL connection..."
    
    # Try connecting without specifying database
    log "Trying connection to localhost:3306..."
    
    if timeout 5 mysql -h localhost -P 3306 -e "SELECT 1 as test" 2>/dev/null; then
        success "✓ Connected to MySQL successfully!"
        mysql -h localhost -P 3306 -e "SHOW DATABASES" 2>/dev/null || warn "Could not list databases"
        return 0
    else
        error "✗ Could not connect to MySQL"
        log "  Common issues:"
        log "  1. SSH tunnel not active in MobaXterm"
        log "  2. MySQL credentials needed" 
        log "  3. Different port number"
        return 1
    fi
}

# Interactive connection setup
setup_connection_interactively() {
    log "Let's set up your MySQL connection interactively..."
    
    echo
    echo "Please provide your MySQL connection details:"
    echo
    
    read -p "MySQL Host (default: localhost): " host
    host=${host:-localhost}
    
    read -p "MySQL Port (default: 3306): " port  
    port=${port:-3306}
    
    read -p "MySQL Username: " username
    
    read -s -p "MySQL Password: " password
    echo
    
    log "Testing connection with provided credentials..."
    
    if mysql -h "$host" -P "$port" -u "$username" -p"$password" -e "SELECT 1 as connection_test" 2>/dev/null; then
        success "✓ Connection successful!"
        
        log "Available databases:"
        mysql -h "$host" -P "$port" -u "$username" -p"$password" -e "SHOW DATABASES" 2>/dev/null
        
        # Save connection info to .env file
        cat > .env << EOF
# MySQL Connection Settings (Generated $(date))
MYSQL_HOST=$host
MYSQL_PORT=$port
MYSQL_USER=$username
MYSQL_PASSWORD=$password
EOF
        
        success "Connection details saved to .env file"
        return 0
    else
        error "Connection failed with provided credentials"
        return 1
    fi
}

# Main function
main() {
    log "Starting MySQL connection diagnostics..."
    
    # Step 1: Check MySQL client
    if ! check_mysql_client; then
        error "Please install MySQL client first:"
        echo "  sudo apt-get update && sudo apt-get install mysql-client"
        exit 1
    fi
    
    # Step 2: Check network
    check_network
    
    # Step 3: Check SSH tunnel
    check_ssh_tunnel
    
    # Step 4: Test connection
    if ! test_mysql_connection; then
        warn "Automatic connection failed"
        
        echo
        read -p "Would you like to set up connection interactively? (y/n): " setup
        
        if [[ "$setup" == "y" || "$setup" == "Y" ]]; then
            setup_connection_interactively
        else
            log "Manual setup required. Edit .env file with your connection details."
        fi
    fi
    
    log "Connection setup complete!"
}

main "$@"