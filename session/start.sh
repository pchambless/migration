#!/bin/bash
# Session Start - Initialize tunnels to both servers
# Usage: ./session/start.sh [prodServer|testServer|both]

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

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Use the v2 tunnel manager
TUNNEL_MANAGER="./tunnel_manager_v2.sh"

main() {
    local target="${1:-both}"
    
    log "🚀 Starting migration session..."
    
    case "$target" in
        "prodServer"|"prod")
            log "Starting production server tunnel..."
            if $TUNNEL_MANAGER start-prod; then
                success "Production server session ready!"
                log "Connect with: mysql -h localhost -P 13306 -u paul -p"
            else
                error "Failed to start production server session"
                exit 1
            fi
            ;;
        "testServer"|"test")
            log "Starting test server tunnel..."
            if $TUNNEL_MANAGER start-test; then
                success "Test server session ready!"
                log "Connect with: mysql -h localhost -P 13307 -u root -p"
            else
                error "Failed to start test server session"
                exit 1
            fi
            ;;
        "both"|*)
            log "Starting both server tunnels..."
            if $TUNNEL_MANAGER start; then
                success "Both server sessions ready!"
                echo
                $TUNNEL_MANAGER status
                echo
                log "🎉 Migration session is active!"
                log "   Production: mysql -h localhost -P 13306 -u paul -p"
                log "   Test:       mysql -h localhost -P 13307 -u root -p"
                echo
                log "Ready to run: ./migration/run.sh"
            else
                error "Failed to start session"
                exit 1
            fi
            ;;
    esac
}

if [[ "${1:-}" == "--help" ]]; then
    echo "Session Start"
    echo "============="
    echo "Usage: $0 [target]"
    echo ""
    echo "Targets:"
    echo "  prodServer  : Start production server tunnel only"
    echo "  testServer  : Start test server tunnel only" 
    echo "  both        : Start both tunnels (default)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Start both servers"
    echo "  $0 prodServer         # Production only"
    echo "  $0 testServer         # Test server only"
    exit 0
fi

main "$@"