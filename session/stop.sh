#!/bin/bash
# Session Stop - Clean shutdown of all tunnels
# Usage: ./session/stop.sh [prodServer|testServer|both]

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
    
    log "🛑 Stopping migration session..."
    
    case "$target" in
        "prodServer"|"prod")
            log "Stopping production server tunnel..."
            if $TUNNEL_MANAGER stop-prod; then
                success "Production server session stopped"
            fi
            ;;
        "testServer"|"test")
            log "Stopping test server tunnel..."
            if $TUNNEL_MANAGER stop-test; then
                success "Test server session stopped"
            fi
            ;;
        "both"|*)
            log "Stopping all tunnels..."
            if $TUNNEL_MANAGER stop; then
                success "All sessions stopped"
                log "🎉 Migration session ended cleanly"
            fi
            ;;
    esac
    
    echo
    log "Session cleanup complete"
}

if [[ "${1:-}" == "--help" ]]; then
    echo "Session Stop"
    echo "============"
    echo "Usage: $0 [target]"
    echo ""
    echo "Targets:"
    echo "  prodServer  : Stop production server tunnel only"
    echo "  testServer  : Stop test server tunnel only"
    echo "  both        : Stop all tunnels (default)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Stop all sessions"
    echo "  $0 prodServer         # Stop production only"
    echo "  $0 testServer         # Stop test server only"
    exit 0
fi

main "$@"