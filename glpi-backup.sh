#!/bin/bash

# -------------------------------------------------------------------------
# @Name: backup-glpi.sh
# @Version: 1.0.0
# @Date: 2024-08-01
# @Author: Allan Lopes Prado
# @License: GNU General Public License v2.0
# @Description: Automates the process of backing up GLPI.
# --------------------------------------------------------------------------
# LICENSE
#
# Backup-GLPI.sh is free software; you can redistribute and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# Backup-GLPI.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software. If not, see <http://www.gnu.org/licenses/>.
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

# VARIABLES
GLPI_DIR="/var/www/html/glpi"
GLPI_CONFIG_DIR="/etc/glpi"
GLPI_DATA_DIR="/var/lib/glpi"
GLPI_LOG_DIR="/var/log/glpi"
GLPI_DUMPS="${GLPI_DATA_DIR}/_dumps"
GLPI_LOGFILE="${GLPI_LOG_DIR}/backup.log"
GLPI_DBCONFIG="${GLPI_CONFIG_DIR}/config_db.php"
LOG_ROTATE_CONF="/etc/logrotate.d/glpi-backup"

# Ensure GLPI directories exist
mkdir -p "$GLPI_DUMPS"
mkdir -p "$GLPI_LOG_DIR"

# CREDENTIALS DATABASE
GLPI_DBUSER=$(grep "dbuser" "$GLPI_DBCONFIG" | cut -d "'" -f 2)
GLPI_DBPASS=$(grep "dbpassword" "$GLPI_DBCONFIG" | cut -d "'" -f 2)

# GLPI VERSION
GLPI_VERSION=$(mysql -u"$GLPI_DBUSER" -p"$GLPI_DBPASS" -D glpi -N -B -e "SELECT value FROM glpi_configs WHERE name = 'version';")

# VARIABLES BACKUP
GLPI_DATE=$(date +%Y-%m-%d-%H-%M)
GLPI_DBNAME=$(grep "dbdefault" "$GLPI_DBCONFIG" | cut -d "'" -f 2)
GLPI_BACKUP_NAME="glpi-${GLPI_VERSION}-${GLPI_DATE}"

# Start backup process
{
    echo "Starting backup at $GLPI_DATE..."
    
    # Backup database
    if mysqldump -u "$GLPI_DBUSER" -p"$GLPI_DBPASS" "$GLPI_DBNAME" | gzip > "${GLPI_DUMPS}/${GLPI_BACKUP_NAME}.sql.gz"; then
        echo "Database backup completed successfully!"
    else
        echo "Database backup failed!"
        exit 1
    fi

    # Backup files including necessary directories
    cd "$GLPI_DIR"
    if tar --exclude='files/_dumps/*' --exclude='files/_uploads/*' \
        -zcf "${GLPI_DATA_DIR}/_uploads/${GLPI_BACKUP_NAME}.files.tar.gz" \
        "$GLPI_DIR" "$CONFIG_DIR" "$VAR_DIR" "$LOG_DIR"; then
        echo "Files backup completed successfully!"
    else
        echo "Files backup failed!"
        exit 1
    fi

    # Remove old backups
    find "$GLPI_DUMPS" -type f -mtime +5 -exec rm -f {} \;
    find "${GLPI_DATA_DIR}/_uploads" -type f -mtime +5 -exec rm -f {} \;

    echo "Backup process completed successfully!"
} >> "$GLPI_LOGFILE" 2>&1

# Setup log rotation
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

exit 0
