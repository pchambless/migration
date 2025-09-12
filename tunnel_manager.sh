#!/bin/bash
# Independent SSH Tunnel Manager
# Creates and manages SSH tunnels for migration, completely separate from MobaXterm

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

# Configuration
CONFIG="./config.json"
TUNNEL_DIR="./tunnels"
PID_FILE="$TUNNEL_DIR/tunnels.pid"

# Port assignments (avoiding conflicts with existing tunnels)
PROD_PORT=13306  # Production: localhost:13306 -> prod:3306
TEST_PORT=13307  # Test: localhost:13307 -> test:3306

# Create tunnel directory
mkdir -p "$TUNNEL_DIR"

# Read server configurations
get_server_config() {
    PROD_HOST=$(jq -r '.source.host' "$CONFIG")
    PROD_USER=$(jq -r '.source.user' "$CONFIG")
    TEST_HOST=$(jq -r '.target.host' "$CONFIG")
    TEST_USER=$(jq -r '.target.user' "$CONFIG")
    TEST_SSH_KEY=$(jq -r '.target.ssh_key // empty' "$CONFIG")
    
    log "Configuration loaded:"
    log "  Production: $PROD_USER@$PROD_HOST -> localhost:$PROD_PORT"
    log "  Test:       $TEST_USER@$TEST_HOST -> localhost:$TEST_PORT"
}

# Kill any existing tunnels managed by this script
cleanup_existing() {
    log "Cleaning up existing tunnels..."
    
    if [[ -f "$PID_FILE" ]]; then
        while IFS= read -r pid; do
            if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                log "Killing existing tunnel PID: $pid"
                kill "$pid" 2>/dev/null || true
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
    
    # Also kill any lingering tunnels on our ports
    local existing_prod=$(lsof -ti:$PROD_PORT 2>/dev/null || true)
    local existing_test=$(lsof -ti:$TEST_PORT 2>/dev/null || true)
    
    if [[ -n "$existing_prod" ]]; then
        log "Killing process using port $PROD_PORT: $existing_prod"
        kill "$existing_prod" 2>/dev/null || true
    fi
    
    if [[ -n "$existing_test" ]]; then
        log "Killing process using port $TEST_PORT: $existing_test"
        kill "$existing_test" 2>/dev/null || true
    fi
    
    # Wait a moment for ports to free up
    sleep 2
}

# Create SSH tunnel with error handling
create_tunnel() {
    local description="$1"
    local local_port="$2"
    local remote_user="$3"
    local remote_host="$4"
    local remote_port="${5:-3306}"
    local ssh_key="${6:-}"
    
    local ssh_cmd="ssh"
    if [[ -n "$ssh_key" ]]; then
        ssh_key=$(eval echo "$ssh_key")  # Expand ~ if present
        ssh_cmd="ssh -i $ssh_key"
        log "Creating $description tunnel with SSH key..."
        log "  Command: $ssh_cmd -L $local_port:localhost:$remote_port -N $remote_user@$remote_host"
    else
        log "Creating $description tunnel..."
        log "  Command: ssh -L $local_port:localhost:$remote_port -N $remote_user@$remote_host"
    fi
    
    # Create tunnel in background and capture PID
    $ssh_cmd -L "$local_port:localhost:$remote_port" -N "$remote_user@$remote_host" &
    local tunnel_pid=$!
    
    # Save PID for cleanup
    echo "$tunnel_pid" >> "$PID_FILE"
    
    # Wait a moment and verify tunnel is running
    sleep 5
    
    if kill -0 "$tunnel_pid" 2>/dev/null; then
        success "$description tunnel established (PID: $tunnel_pid)"
        return 0
    else
        error "$description tunnel failed to start"
        return 1
    fi
}

# Test if ports are accessible
test_ports() {
    log "Testing tunnel ports..."
    
    local success_count=0
    
    # Test production port
    if nc -z localhost "$PROD_PORT" 2>/dev/null; then
        success "✓ Production port $PROD_PORT is accessible"
        ((success_count++))
    else
        error "✗ Production port $PROD_PORT is not accessible"
    fi
    
    # Test test server port
    if nc -z localhost "$TEST_PORT" 2>/dev/null; then
        success "✓ Test server port $TEST_PORT is accessible"
        ((success_count++))
    else
        error "✗ Test server port $TEST_PORT is not accessible"
    fi
    
    return $((2 - success_count))
}

# Test MySQL connections through tunnels
test_mysql() {
    log "Testing MySQL connections..."
    
    echo "Enter credentials for MySQL testing:"
    
    # Test production MySQL
    read -s -p "Production MySQL password for $PROD_USER: " prod_pass
    echo
    
    log "Testing production MySQL connection..."
    if mysql -h localhost -P "$PROD_PORT" -u "$PROD_USER" -p"$prod_pass" -e "SELECT 'Production connection successful' as result" 2>/dev/null; then
        success "✓ Production MySQL connection works"
    else
        error "✗ Production MySQL connection failed"
    fi
    
    # Test staging MySQL
    read -s -p "Test server MySQL password for $TEST_USER: " test_pass
    echo
    
    log "Testing test server MySQL connection..."
    if mysql -h localhost -P "$TEST_PORT" -u "$TEST_USER" -p"$test_pass" -e "SELECT 'Test server connection successful' as result" 2>/dev/null; then
        success "✓ Test server MySQL connection works"
    else
        error "✗ Test server MySQL connection failed"
    fi
}

# Show tunnel status
show_status() {
    log "Tunnel Status Report:"
    
    if [[ ! -f "$PID_FILE" ]]; then
        warn "No tunnel PID file found - tunnels may not be running"
        return 1
    fi
    
    local active_count=0
    
    while IFS= read -r pid; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            success "Tunnel PID $pid: ACTIVE"
            ((active_count++))
        else
            warn "Tunnel PID $pid: INACTIVE"
        fi
    done < "$PID_FILE"
    
    log "Active tunnels: $active_count"
    log "Port assignments:"
    log "  Production: localhost:$PROD_PORT"
    log "  Test:       localhost:$TEST_PORT"
    
    # Test port accessibility
    test_ports
}

# Setup tunnels
setup_tunnels() {
    log "🚀 Setting up independent SSH tunnels..."
    
    get_server_config
    cleanup_existing
    
    log "Creating tunnels..."
    
    # Create production tunnel
    if create_tunnel "Production" "$PROD_PORT" "$PROD_USER" "$PROD_HOST"; then
        success "Production tunnel ready"
    else
        error "Failed to create production tunnel"
        cleanup_existing
        return 1
    fi
    
    # Create test tunnel  
    if create_tunnel "Test" "$TEST_PORT" "$TEST_USER" "$TEST_HOST" "3306" "$TEST_SSH_KEY"; then
        success "Test tunnel ready"
    else
        error "Failed to create test tunnel"
        cleanup_existing
        return 1
    fi
    
    log "Both tunnels established!"
    
    # Give tunnels extra time to fully initialize
    log "Waiting for tunnels to fully initialize..."
    sleep 3
    
    if test_ports; then
        success "All tunnels are working!"
    else
        warn "Some tunnels may have issues, but continuing..."
        show_status
    fi
}

# Cleanup function
cleanup() {
    log "Cleaning up tunnels..."
    cleanup_existing
    success "Cleanup complete"
}

# Main function
main() {
    case "${1:-setup}" in
        "setup"|"start")
            setup_tunnels
            ;;
        "test")
            test_mysql
            ;;
        "status")
            show_status
            ;;
        "stop"|"cleanup")
            cleanup
            ;;
        "ports")
            log "Port assignments:"
            log "  Production MySQL: localhost:$PROD_PORT"
            log "  Test MySQL:       localhost:$TEST_PORT"
            ;;
        *)
            echo "SSH Tunnel Manager"
            echo "=================="
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  setup     : Create SSH tunnels to both servers"
            echo "  test      : Test MySQL connections through tunnels"
            echo "  status    : Show tunnel status"
            echo "  stop      : Stop all managed tunnels"
            echo "  ports     : Show port assignments"
            echo ""
            echo "Port Assignments:"
            echo "  Production: localhost:$PROD_PORT -> $PROD_USER@$PROD_HOST:3306"
            echo "  Test:       localhost:$TEST_PORT -> $TEST_USER@$TEST_HOST:3306"
            exit 0
            ;;
    esac
}

# Don't auto-cleanup on exit during setup - only on explicit cleanup

main "$@"