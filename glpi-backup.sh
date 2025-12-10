#!/bin/bash

# -------------------------------------------------------------------------
# @Name: glpi-backup.sh
# @Version: 1.2.0
# @Date: 2024-08-08
# @Author: Allan Lopes Prado
# @License: GNU General Public License v2.0
# @Description: Automates the BACKUP of GLPI (Files and Database).
# --------------------------------------------------------------------------
# LICENSE
#
# glpi-backup.sh is free software; you can redistribute and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# glpi-backup.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software. If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 1. PRE-FLIGHT & SAFETY SETTINGS
# ------------------------------------------------------------------------------
# Exit immediately if a command exits with a non-zero status.
set -o errexit
# Treat unset variables as an error.
set -o nounset
# Return value of a pipeline is the status of the last command to exit with a non-zero status.
set -o pipefail

# Configuration and Constants
CONFIG_FILE="/etc/glpi/glpi-backup.conf"
LOCK_FILE="/tmp/glpi-backup.lock"
START_TIME=$(date +%s)
DATE_TAG=$(date +"%Y-%m-%d_%H%M%S")

# ANSI Colors for Terminal Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# 2. HELPER FUNCTIONS
# ------------------------------------------------------------------------------

# Logging function: writes to stdout and log file
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_entry="[$timestamp] [$level] $message"

    # Write to Log File (ensure directory exists first)
    if [ ! -z "${LOG_FILE:-}" ]; then
        mkdir -p "$(dirname "$LOG_FILE")"
        echo "$log_entry" >> "$LOG_FILE"
    fi

    # Print to Terminal with colors
    case "$level" in
        "INFO")    echo -e "${CYAN}[INFO]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[OK]${NC} $message" ;;
        "WARN")    echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR")   echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
    esac
}

# Notification function (Webhook)
send_notification() {
    local status="$1"
    local message="$2"

    if [[ -n "${WEBHOOK_URL:-}" ]]; then
        # Simple JSON payload
        local json_payload="{\"username\": \"GLPI Backup Bot\", \"content\": \"**$status**: $SERVER_NAME - $message\"}"
        
        curl -s -H "Content-Type: application/json" \
             -X POST \
             -d "$json_payload" \
             "$WEBHOOK_URL" >/dev/null 2>&1 || true
    fi
}

# Cleanup function: Runs on exit (success or failure)
cleanup() {
    # Remove temporary directory
    if [[ -d "${TEMP_DIR:-}" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    # Remove secure mysql config
    if [[ -f "${SECURE_CNF:-}" ]]; then
        rm -f "$SECURE_CNF"
    fi
    # Release Lock
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# Error Handler: Runs on script failure
error_handler() {
    local line_no=$1
    local error_code=$2
    log "ERROR" "Script failed at line $line_no with error code $error_code."
    send_notification "FAILURE" "Backup failed abruptly at line $line_no."
    exit $error_code
}
trap 'error_handler ${LINENO} $?' ERR

# Check for required system commands
check_dependencies() {
    local dependencies=(mysqldump tar gzip awk curl sha256sum)
    for cmd in "${dependencies[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            log "ERROR" "Required command not found: $cmd"
            exit 1
        fi
    done
}

# ------------------------------------------------------------------------------
# 3. INITIALIZATION
# ------------------------------------------------------------------------------

# Check for Lock File (Prevent Overlap)
if [ -e "$LOCK_FILE" ]; then
    echo "ERROR: Script is already running (Lock file exists at $LOCK_FILE)."
    exit 1
fi
touch "$LOCK_FILE"

# Load Configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

log "INFO" "Starting GLPI Enterprise Backup Sequence..."

# System Health Checks
check_dependencies

# Prepare Destination Directory
if [ ! -d "$BACKUP_ROOT" ]; then
    mkdir -p "$BACKUP_ROOT"
    chmod 700 "$BACKUP_ROOT" # Restrict access to root only
fi

# Check Disk Space
AVAILABLE_SPACE=$(df -m "$BACKUP_ROOT" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt "$MIN_DISK_SPACE_MB" ]; then
    log "ERROR" "Insufficient disk space. Available: ${AVAILABLE_SPACE}MB, Required: ${MIN_DISK_SPACE_MB}MB."
    send_notification "FAILURE" "Disk space low. Backup aborted."
    exit 1
fi

# Create Atomic Temporary Directory
TEMP_DIR=$(mktemp -d)
chmod 700 "$TEMP_DIR"

# ------------------------------------------------------------------------------
# 4. DATABASE BACKUP
# ------------------------------------------------------------------------------
log "INFO" "Starting Database Dump: $DB_NAME"

DB_FILE_NAME="glpi_db_${DATE_TAG}.sql.gz"
DB_FILE_PATH="$TEMP_DIR/$DB_FILE_NAME"

# Securely create MySQL config to avoid exposing password in process list
SECURE_CNF="$TEMP_DIR/.my.cnf"
umask 077 # Only owner can read
cat > "$SECURE_CNF" <<EOF
[client]
user=$DB_USER
password=$DB_PASS
host=$DB_HOST
EOF
umask 0022 # Reset umask

# Execute Dump
# --single-transaction: Consistency for InnoDB without locking
# --quick: Row-by-row retrieval
mysqldump --defaults-extra-file="$SECURE_CNF" \
    --single-transaction \
    --quick \
    --routines \
    --triggers \
    "$DB_NAME" | gzip > "$DB_FILE_PATH"

log "SUCCESS" "Database dumped successfully."

# ------------------------------------------------------------------------------
# 5. FILESYSTEM BACKUP
# ------------------------------------------------------------------------------
log "INFO" "Starting File System Backup: $GLPI_DIR"

FILES_FILE_NAME="glpi_files_${DATE_TAG}.tar.gz"
FILES_FILE_PATH="$TEMP_DIR/$FILES_FILE_NAME"

# Exclude existing backups or temp files to avoid recursion loop
EXCLUDES="--exclude=*.sql.gz --exclude=*.tar.gz --exclude=$BACKUP_ROOT"

# Check if GLPI directory exists
if [ ! -d "$GLPI_DIR" ]; then
    log "ERROR" "GLPI Directory not found: $GLPI_DIR"
    exit 1
fi

tar -czf "$FILES_FILE_PATH" $EXCLUDES -C "$(dirname "$GLPI_DIR")" "$(basename "$GLPI_DIR")"

log "SUCCESS" "Files compressed successfully."

# ------------------------------------------------------------------------------
# 6. INTEGRITY & FINALIZATION
# ------------------------------------------------------------------------------
log "INFO" "Generating SHA256 Checksums for integrity verification..."

cd "$TEMP_DIR"
sha256sum "$DB_FILE_NAME" "$FILES_FILE_NAME" > "checksums.sha256"

log "INFO" "Moving artifacts to final destination..."

# Create daily folder structure for organization
FINAL_DEST="$BACKUP_ROOT/$DATE_TAG"
mkdir -p "$FINAL_DEST"

# Move files
mv "$TEMP_DIR"/* "$FINAL_DEST/"
chmod 600 "$FINAL_DEST"/* # Lock down file permissions

log "SUCCESS" "Backup stored securely at: $FINAL_DEST"

# ------------------------------------------------------------------------------
# 7. RETENTION POLICY (CLEANUP)
# ------------------------------------------------------------------------------
log "INFO" "Applying retention policy (Keeping last $RETENTION_DAYS days)..."

# Find directories in backup root older than X days and remove them
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +$RETENTION_DAYS -exec rm -rf {} +

log "SUCCESS" "Cleanup completed."

# ------------------------------------------------------------------------------
# 8. CONCLUSION
# ------------------------------------------------------------------------------
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

log "INFO" "Backup process finished successfully in ${DURATION} seconds."
send_notification "SUCCESS" "Backup completed in ${DURATION}s. Location: $FINAL_DEST"

exit 0
