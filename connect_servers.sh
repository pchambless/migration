#!/bin/bash
# Two-Server Connection Manager
# Manages SSH tunnels to both production and test servers

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
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

CONFIG="./config.json"
TUNNEL_DIR="./tunnels"

# Create tunnel tracking directory
mkdir -p "$TUNNEL_DIR"

# Read server configurations
PROD_HOST=$(jq -r '.source.host' "$CONFIG")
PROD_USER=$(jq -r '.source.user' "$CONFIG")
TEST_HOST=$(jq -r '.target.host' "$CONFIG") 
TEST_USER=$(jq -r '.target.user' "$CONFIG")

# Setup SSH tunnel for production server
setup_prod_tunnel() {
    log "Setting up tunnel to production server: $PROD_HOST"
    
    # Kill existing tunnel if any
    if [[ -f "$TUNNEL_DIR/prod.pid" ]]; then
        local old_pid=$(cat "$TUNNEL_DIR/prod.pid")
        kill "$old_pid" 2>/dev/null || true
        rm -f "$TUNNEL_DIR/prod.pid"
    fi
    
    # Create new tunnel (local port 3306 -> prod server port 3306)
    ssh -L 3306:localhost:3306 -N -f "$PROD_USER@$PROD_HOST"
    echo $! > "$TUNNEL_DIR/prod.pid"
    
    success "Production tunnel established: localhost:3306 -> $PROD_HOST:3306"
}

# Setup SSH tunnel for test server  
setup_test_tunnel() {
    log "Setting up tunnel to test server: $TEST_HOST"
    
    # Kill existing tunnel if any
    if [[ -f "$TUNNEL_DIR/test.pid" ]]; then
        local old_pid=$(cat "$TUNNEL_DIR/test.pid")
        kill "$old_pid" 2>/dev/null || true
        rm -f "$TUNNEL_DIR/test.pid"
    fi
    
    # Create new tunnel (local port 3307 -> test server port 3306)
    ssh -L 3307:localhost:3306 -N -f "$TEST_USER@$TEST_HOST"
    echo $! > "$TUNNEL_DIR/test.pid"
    
    success "Test tunnel established: localhost:3307 -> $TEST_HOST:3306"
}

# Test tunnel connections
test_tunnels() {
    log "Testing tunnel connections..."
    
    # Test production tunnel
    log "Testing production connection (port 3306)..."
    if nc -z localhost 3306 2>/dev/null; then
        success "✓ Production tunnel is active"
    else
        error "✗ Production tunnel failed"
        return 1
    fi
    
    # Test staging tunnel
    log "Testing test server connection (port 3307)..."
    if nc -z localhost 3307 2>/dev/null; then
        success "✓ Test server tunnel is active"
    else
        error "✗ Test server tunnel failed"
        return 1
    fi
}

# Test MySQL connections through tunnels
test_mysql_connections() {
    log "Testing MySQL connections through tunnels..."
    
    # Test production MySQL
    log "Testing production MySQL..."
    read -s -p "Enter password for $PROD_USER@$PROD_HOST: " prod_pass
    echo
    
    if mysql -h localhost -P 3306 -u "$PROD_USER" -p"$prod_pass" -e "SELECT 1 as prod_test" 2>/dev/null; then
        success "✓ Production MySQL connection works"
        mysql -h localhost -P 3306 -u "$PROD_USER" -p"$prod_pass" -e "SHOW DATABASES" | grep -E "(whatsfresh|wf_meta)"
    else
        error "✗ Production MySQL connection failed"
    fi
    
    echo
    
    # Test staging MySQL
    log "Testing test server MySQL..."
    read -s -p "Enter password for $TEST_USER@$TEST_HOST: " test_pass
    echo
    
    if mysql -h localhost -P 3307 -u "$TEST_USER" -p"$test_pass" -e "SELECT 1 as test_test" 2>/dev/null; then
        success "✓ Test server MySQL connection works"
        mysql -h localhost -P 3307 -u "$TEST_USER" -p"$test_pass" -e "SHOW DATABASES" | grep -E "(whatsfresh|wf_meta)" || warn "Databases may be different on test server"
    else
        error "✗ Test server MySQL connection failed"
    fi
}

# Clean up tunnels
cleanup_tunnels() {
    log "Cleaning up SSH tunnels..."
    
    if [[ -f "$TUNNEL_DIR/prod.pid" ]]; then
        local prod_pid=$(cat "$TUNNEL_DIR/prod.pid")
        kill "$prod_pid" 2>/dev/null || true
        rm -f "$TUNNEL_DIR/prod.pid"
        log "Production tunnel closed"
    fi
    
    if [[ -f "$TUNNEL_DIR/test.pid" ]]; then
        local test_pid=$(cat "$TUNNEL_DIR/test.pid")
        kill "$test_pid" 2>/dev/null || true
        rm -f "$TUNNEL_DIR/test.pid"
        log "Test tunnel closed"
    fi
    
    success "All tunnels cleaned up"
}

# Show tunnel status
show_status() {
    log "Tunnel Status:"
    
    if [[ -f "$TUNNEL_DIR/prod.pid" ]] && kill -0 "$(cat "$TUNNEL_DIR/prod.pid")" 2>/dev/null; then
        success "Production tunnel: ACTIVE (localhost:3306 -> $PROD_HOST)"
    else
        warn "Production tunnel: INACTIVE"
    fi
    
    if [[ -f "$TUNNEL_DIR/test.pid" ]] && kill -0 "$(cat "$TUNNEL_DIR/test.pid")" 2>/dev/null; then
        success "Test tunnel: ACTIVE (localhost:3307 -> $TEST_HOST)"
    else
        warn "Test tunnel: INACTIVE" 
    fi
}

# Main function
main() {
    case "${1:-setup}" in
        "setup")
            log "🚀 Setting up tunnels to both servers..."
            setup_prod_tunnel
            sleep 2
            setup_test_tunnel
            sleep 2
            test_tunnels
            show_status
            ;;
        "test")
            test_mysql_connections
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup_tunnels
            ;;
        *)
            echo "Usage: $0 [setup|test|status|cleanup]"
            echo "  setup   : Create SSH tunnels to both servers"
            echo "  test    : Test MySQL connections through tunnels"
            echo "  status  : Show tunnel status"
            echo "  cleanup : Close all tunnels"
            exit 1
            ;;
    esac
}

# Cleanup on script exit
trap cleanup_tunnels EXIT

main "$@"