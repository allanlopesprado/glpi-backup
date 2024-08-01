#!/bin/bash
set -euo pipefail

# -------------------------------------------------------------------------
# @Name: Backup-GLPI.sh
# @Version: 2.1.0
# @Date: 2024-08-01
# @Author: Allan Lopes Prado
# @License: GNU General Public License v3.0
# @Description: This script performs automatic backups for GLPI.
# --------------------------------------------------------------------------

# Load configuration
source "/etc/backup-glpi.conf"

# Functions
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$GLPI_LOG_DIR/backup.log"
}

error_handler() {
    local exit_code=$?
    local line_number=$1
    log_message "Script error at line $line_number. Exit code: $exit_code"
    exit $exit_code
}

check_prerequisites() {
    if [ ! -d "$GLPI_DIR" ] || [ ! -d "$GLPI_DATA_DIR" ] || [ ! -f "$GLPI_CONFIG_DIR/config_db.php" ]; then
        log_message "Error: GLPI directory or configuration file not found."
        exit 1
    fi

    if [ "$(id -u)" -ne 0 ]; then
        log_message "Error: Script must be run as root."
        exit 1
    fi
}

extract_db_credentials() {
    DB_USER=$(grep "dbuser" "$GLPI_CONFIG_DIR/config_db.php" | cut -d "'" -f 2)
    DB_PASS=$(grep "dbpassword" "$GLPI_CONFIG_DIR/config_db.php" | cut -d "'" -f 2)
    DB_NAME=$(grep "dbdefault" "$GLPI_CONFIG_DIR/config_db.php" | cut -d "'" -f 2)

    if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ]; then
        log_message "Error: Could not retrieve database credentials."
        exit 1
    fi
}

get_glpi_version() {
    GLPI_VERSION=$(mysql -u"$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -B -e "SELECT value FROM glpi_configs WHERE name = 'version';")

    if [ -z "$GLPI_VERSION" ]; then
        log_message "Error: Could not retrieve GLPI version."
        exit 1
    fi
}

perform_backup() {
    local backup_date=$(date +%Y-%m-%d-%H-%M)
    local backup_file_sql="$GLPI_DATA_DIR/glpi-${GLPI_VERSION}-${backup_date}.sql.gz"
    local backup_file_tar="$GLPI_DATA_DIR/glpi-${GLPI_VERSION}-${backup_date}.files.tar.gz"
