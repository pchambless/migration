#!/bin/bash
# Logging functions for migration

# Basic logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[SUCCESS] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING] $1" >> "$LOG_FILE"
}

dry_run() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $1"
    echo "[DRY-RUN] $1" >> "$LOG_FILE"
}

# Step logging
log_step_start() {
    local step_name="$1"
    echo
    echo "================================================================="
    log "🚀 Starting: $step_name"
    echo "================================================================="
    # Write to log file without colors
    echo >> "$LOG_FILE"
    echo "=================================================================" >> "$LOG_FILE"
    echo "=================================================================" >> "$LOG_FILE"
}

log_step_success() {
    local step_name="$1"
    local message="$2"
    echo "================================================================="
    success "✅ Completed: $step_name - $message"
    echo "================================================================="
    echo
    # Write to log file without colors
    echo "=================================================================" >> "$LOG_FILE"
    echo "=================================================================" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
}

log_step_error() {
    local step_name="$1"
    local message="$2"
    echo "================================================================="
    error "❌ Failed: $step_name - $message"
    echo "================================================================="
    echo
    # Write to log file without colors
    echo "=================================================================" >> "$LOG_FILE"
    echo "=================================================================" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
}