#!/bin/bash
# Independent SSH Tunnel Manager v2
# Separate controls for production and test server tunnels

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
PROD_PID_FILE="$TUNNEL_DIR/prod.pid"
TEST_PID_FILE="$TUNNEL_DIR/test.pid"

# Port assignments
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
}

# Start production tunnel
start_prod_tunnel() {
    log "🔵 Starting production tunnel..."
    get_server_config
    
    # Kill existing production tunnel
    if [[ -f "$PROD_PID_FILE" ]]; then
        local old_pid=$(cat "$PROD_PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            log "Stopping existing production tunnel (PID: $old_pid)"
            kill "$old_pid" 2>/dev/null || true
        fi
        rm -f "$PROD_PID_FILE"
    fi
    
    # Clear port if in use
    local existing=$(lsof -ti:$PROD_PORT 2>/dev/null || true)
    if [[ -n "$existing" ]]; then
        log "Clearing port $PROD_PORT (PID: $existing)"
        kill "$existing" 2>/dev/null || true
        sleep 2
    fi
    
    log "Creating production tunnel: localhost:$PROD_PORT -> $PROD_USER@$PROD_HOST:3306"
    
    # Start tunnel interactively first, then background
    log "Please enter password for $PROD_USER@$PROD_HOST when prompted..."
    ssh -f -L "$PROD_PORT:localhost:3306" -N "$PROD_USER@$PROD_HOST"
    
    # Get the PID of the backgrounded SSH process
    local tunnel_pid=$(pgrep -f "ssh.*$PROD_PORT:localhost:3306.*$PROD_USER@$PROD_HOST")
    echo "$tunnel_pid" > "$PROD_PID_FILE"
    
    # Wait and verify
    sleep 2
    if kill -0 "$tunnel_pid" 2>/dev/null; then
        success "✅ Production tunnel started (PID: $tunnel_pid)"
        log "   Connect with: mysql -h localhost -P $PROD_PORT -u $PROD_USER -p"
    else
        error "❌ Production tunnel failed to start"
        rm -f "$PROD_PID_FILE"
        return 1
    fi
}

# Start test tunnel
start_test_tunnel() {
    log "🟢 Starting test tunnel..."
    get_server_config
    
    # Kill existing test tunnel
    if [[ -f "$TEST_PID_FILE" ]]; then
        local old_pid=$(cat "$TEST_PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            log "Stopping existing test tunnel (PID: $old_pid)"
            kill "$old_pid" 2>/dev/null || true
        fi
        rm -f "$TEST_PID_FILE"
    fi
    
    # Clear port if in use
    local existing=$(lsof -ti:$TEST_PORT 2>/dev/null || true)
    if [[ -n "$existing" ]]; then
        log "Clearing port $TEST_PORT (PID: $existing)"
        kill "$existing" 2>/dev/null || true
        sleep 2
    fi
    
    # Prepare SSH command with key if specified
    local ssh_cmd="ssh"
    if [[ -n "$TEST_SSH_KEY" ]]; then
        TEST_SSH_KEY=$(eval echo "$TEST_SSH_KEY")  # Expand ~
        ssh_cmd="ssh -i $TEST_SSH_KEY"
        log "Creating test tunnel with SSH key: localhost:$TEST_PORT -> $TEST_USER@$TEST_HOST:3306"
    else
        log "Creating test tunnel: localhost:$TEST_PORT -> $TEST_USER@$TEST_HOST:3306"
    fi
    
    # Start tunnel (hardcode root for SSH, wf_admin is for MySQL only)
    $ssh_cmd -L "$TEST_PORT:localhost:3306" -N "root@$TEST_HOST" &
    local tunnel_pid=$!
    echo "$tunnel_pid" > "$TEST_PID_FILE"
    
    # Wait and verify
    sleep 3
    if kill -0 "$tunnel_pid" 2>/dev/null; then
        success "✅ Test tunnel started (PID: $tunnel_pid)"
        log "   Connect with: mysql -h localhost -P $TEST_PORT -u $TEST_USER -p"
    else
        error "❌ Test tunnel failed to start"
        rm -f "$TEST_PID_FILE"
        return 1
    fi
}

# Stop production tunnel
stop_prod_tunnel() {
    log "🔴 Stopping production tunnel..."
    
    if [[ -f "$PROD_PID_FILE" ]]; then
        local pid=$(cat "$PROD_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            success "Production tunnel stopped (PID: $pid)"
        else
            warn "Production tunnel was not running"
        fi
        rm -f "$PROD_PID_FILE"
    else
        warn "No production tunnel PID file found"
    fi
}

# Stop test tunnel
stop_test_tunnel() {
    log "🔴 Stopping test tunnel..."
    
    if [[ -f "$TEST_PID_FILE" ]]; then
        local pid=$(cat "$TEST_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            success "Test tunnel stopped (PID: $pid)"
        else
            warn "Test tunnel was not running"
        fi
        rm -f "$TEST_PID_FILE"
    else
        warn "No test tunnel PID file found"
    fi
}

# Show status
show_status() {
    log "📊 Tunnel Status:"
    get_server_config
    
    # Production status
    if [[ -f "$PROD_PID_FILE" ]] && kill -0 "$(cat "$PROD_PID_FILE")" 2>/dev/null; then
        local prod_pid=$(cat "$PROD_PID_FILE")
        success "🔵 Production tunnel: ACTIVE (PID: $prod_pid)"
        log "   Port: localhost:$PROD_PORT -> $PROD_USER@$PROD_HOST:3306"
        
        if nc -z localhost "$PROD_PORT" 2>/dev/null; then
            success "   ✓ Port $PROD_PORT is accessible"
        else
            warn "   ⚠ Port $PROD_PORT not accessible (starting up?)"
        fi
    else
        warn "🔵 Production tunnel: INACTIVE"
    fi
    
    echo
    
    # Test status
    if [[ -f "$TEST_PID_FILE" ]] && kill -0 "$(cat "$TEST_PID_FILE")" 2>/dev/null; then
        local test_pid=$(cat "$TEST_PID_FILE")
        success "🟢 Test tunnel: ACTIVE (PID: $test_pid)"
        log "   Port: localhost:$TEST_PORT -> $TEST_USER@$TEST_HOST:3306"
        
        if nc -z localhost "$TEST_PORT" 2>/dev/null; then
            success "   ✓ Port $TEST_PORT is accessible"
        else
            warn "   ⚠ Port $TEST_PORT not accessible (starting up?)"
        fi
    else
        warn "🟢 Test tunnel: INACTIVE"
    fi
}

# Test connections
test_connections() {
    log "🧪 Testing MySQL connections..."
    
    show_status
    
    echo
    log "Manual connection commands:"
    log "  Production: mysql -h localhost -P $PROD_PORT -u paul -p"
    log "  Test:       mysql -h localhost -P $TEST_PORT -u root -p"
}

# Main function
main() {
    case "${1:-help}" in
        "start-prod")
            start_prod_tunnel
            ;;
        "start-test")
            start_test_tunnel
            ;;
        "start-both"|"start")
            start_prod_tunnel
            echo
            start_test_tunnel
            echo
            show_status
            ;;
        "stop-prod")
            stop_prod_tunnel
            ;;
        "stop-test")
            stop_test_tunnel
            ;;
        "stop-both"|"stop")
            stop_prod_tunnel
            stop_test_tunnel
            success "All tunnels stopped"
            ;;
        "status")
            show_status
            ;;
        "test")
            test_connections
            ;;
        "restart-prod")
            stop_prod_tunnel
            sleep 1
            start_prod_tunnel
            ;;
        "restart-test")
            stop_test_tunnel
            sleep 1
            start_test_tunnel
            ;;
        "help"|*)
            echo "SSH Tunnel Manager v2 - Independent Control"
            echo "=========================================="
            echo "Usage: $0 [command]"
            echo ""
            echo "Individual Tunnel Control:"
            echo "  start-prod    : Start production tunnel only"
            echo "  start-test    : Start test server tunnel only"
            echo "  stop-prod     : Stop production tunnel only"
            echo "  stop-test     : Stop test server tunnel only"
            echo "  restart-prod  : Restart production tunnel"
            echo "  restart-test  : Restart test server tunnel"
            echo ""
            echo "Batch Operations:"
            echo "  start         : Start both tunnels"
            echo "  stop          : Stop both tunnels"
            echo "  status        : Show status of both tunnels"
            echo "  test          : Show connection test commands"
            echo ""
            echo "Port Assignments:"
            echo "  Production: localhost:$PROD_PORT -> paul@whatsfresh.app:3306"
            echo "  Test:       localhost:$TEST_PORT -> root@159.223.104.19:3306"
            echo ""
            echo "Troubleshooting Workflow:"
            echo "  1. $0 start-prod     # Test production only"
            echo "  2. $0 start-test     # Test staging only"
            echo "  3. $0 status         # Check both"
            echo "  4. Run migration"
            echo "  5. $0 stop           # Clean shutdown"
            exit 0
            ;;
    esac
}

main "$@"