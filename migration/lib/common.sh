#!/bin/bash
# Main common library - sources all modules

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all modules
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/logging.sh" 
source "$SCRIPT_DIR/connectivity.sh"
source "$SCRIPT_DIR/mysql_helper.sh"
source "$SCRIPT_DIR/database.sh"

# Export functions and variables that should be available to calling scripts
export -f log success error warn dry_run
export -f log_step_start log_step_success log_step_error
export -f check_tunnels
export -f execute_procedure copy_table
export LOG_FILE