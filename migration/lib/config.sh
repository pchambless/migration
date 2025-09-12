#!/bin/bash
# Configuration and constants for migration

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration  
CONFIG="config.json"
LOG_DIR="migration-logs"
# Use exported timestamp from main script, or create new one
TIMESTAMP=${MIGRATION_TIMESTAMP:-$(date '+%y-%m-%d %H:%M')}
LOG_FILE="$LOG_DIR/$TIMESTAMP migration.log"

# Port assignments
PROD_PORT=13306
TEST_PORT=13307

# Dry run mode (set by --dry-run flag)
DRY_RUN=${DRY_RUN:-false}

# Create log directory
mkdir -p "$LOG_DIR"

# Read database users from config
PROD_USER=$(jq -r '.source.user' "$CONFIG")
TEST_USER=$(jq -r '.target.user' "$CONFIG")