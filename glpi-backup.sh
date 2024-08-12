#!/bin/bash

# -------------------------------------------------------------------------
# @Name: backup-glpi.sh
# @Version: 1.0.0
# @Date: 2024-08-01
# @Author: Allan Lopes Prado
# @License: GNU General Public License v2.0
# @Description: Automates the process of backing up GLPI.
# --------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# Print usage information
usage() {
    echo "Usage: $0"
    echo "    - Perform automatic backups for GLPI"
    echo "    - Logs backup operations to /var/log/glpi/backup.log"
    exit 1
}

# Check if the script is run as root
if [ "$(id -u)" -ne "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Load configuration file
echo "Loading configuration from /etc/glpi-backup.conf..."
source /etc/glpi-backup.conf

# VARIABLES
GLPI_DUMPS="${GLPI_DATA_DIR}/_dumps"
GLPI_LOGFILE="${GLPI_LOG_DIR}/backup.log"
LOG_ROTATE_CONF="/etc/logrotate.d/glpi-backup"

# Ensure GLPI directories exist
echo "Ensuring GLPI directories exist..."
mkdir -p "$GLPI_DUMPS"
mkdir -p "$GLPI_LOG_DIR"

# CREDENTIALS DATABASE
GLPI_DBUSER="$DB_USER"
GLPI_DBPASS="$DB_PASS"
GLPI_DBNAME="$DB_NAME"

# GLPI VERSION
echo "Retrieving GLPI version..."
GLPI_VERSION=$(mysql -u"$GLPI_DBUSER" -p"$GLPI_DBPASS" -D "$GLPI_DBNAME" -N -B -e "SELECT value FROM glpi_configs WHERE name = 'version';")

# VARIABLES BACKUP
GLPI_DATE=$(date +%Y-%m-%d-%H-%M)
GLPI_BACKUP_NAME="glpi-${GLPI_VERSION}-${GLPI_DATE}"

# Start backup process
echo "Starting backup process at $GLPI_DATE..."

{
    # Backup database
    echo "Backing up the database..."
    if mysqldump -u "$GLPI_DBUSER" -p"$GLPI_DBPASS" "$GLPI_DBNAME" | gzip > "${GLPI_DUMPS}/${GLPI_BACKUP_NAME}.sql.gz"; then
        echo "Database backup completed successfully!"
    else
        echo "Database backup failed!"
        exit 1
    fi

    # Backup files including necessary directories
    echo "Backing up files..."
    cd "$GLPI_DIR"
    if tar --exclude='files/_dumps/*' --exclude='files/_uploads/*' \
        -zcf "${GLPI_DATA_DIR}/_uploads/${GLPI_BACKUP_NAME}.files.tar.gz" \
        "$GLPI_DIR"; then
        echo "Files backup completed successfully!"
    else
        echo "Files backup failed!"
        exit 1
    fi

    # Remove old backups
    echo "Removing old backups..."
    find "$GLPI_DUMPS" -type f -mtime +5 -exec rm -f {} \;
    find "${GLPI_DATA_DIR}/_uploads" -type f -mtime +5 -exec rm -f {} \;

    echo "Backup process completed successfully!"
} >> "$GLPI_LOGFILE" 2>&1

# Setup log rotation
echo "Setting up log rotation..."
if [ ! -f "$LOG_ROTATE_CONF" ]; then
    cat <<EOL > "$LOG_ROTATE_CONF"
$GLPI_LOGFILE {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0640 root root
}
EOL
    echo "Log rotation configuration added for $GLPI_LOGFILE"
fi

echo "Backup process completed successfully! The backup files are located in /var/lib/glpi/_dumps and /var/lib/glpi/_uploads."
exit 0
