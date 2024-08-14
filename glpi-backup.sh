#!/bin/bash

# -------------------------------------------------------------------------
# @Name: glpi-backup.sh
# @Version: 1.0.0
# @Date: 2024-08-08
# @Author: Allan Lopes Prado
# @License: GNU General Public License v2.0
# @Description: Automates the installation of GLPI.
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

# Configuration file
BACKUP_CONFIG="/var/glpi-backup/glpi-backup.conf"

# Function to read variables from the configuration file
read_config() {
    local key="$1"
    grep "^${key}=" "$BACKUP_CONFIG" | cut -d'=' -f2 | tr -d '"'
}

# Read variables from the configuration file
GLPI_DIR=$(read_config "GLPI_DIR")
GLPI_DATA_DIR=$(read_config "GLPI_DATA_DIR")
DB_HOST=$(read_config "DB_HOST")
DB_NAME=$(read_config "DB_NAME")
DB_USER=$(read_config "DB_USER")
DB_PASS=$(read_config "DB_PASS")
BACKUP_RETENTION_DAYS=$(read_config "BACKUP_RETENTION_DAYS")

# Directory where backups will be saved
BACKUP_DIR="/var/lib/glpi/_dumps"

# Date and time for file naming
DATE=$(date +"%Y%m%d%H%M%S")

# Backup files
GLPI_BACKUP_FILE="${BACKUP_DIR}/glpi_dir_backup_${DATE}.tar.gz"
GLPI_BACKUP_DATA_FILE="${BACKUP_DIR}/glpi_data_backup_${DATE}.tar.gz"
DB_BACKUP_FILE="${BACKUP_DIR}/glpi_db_backup_${DATE}.sql.gz"

# Progress messages
echo "Starting directory backups..."

# Exclude specified directories
EXCLUDES="--exclude=${GLPI_DIR}/files/_dumps --exclude=${GLPI_DATA_DIR}/_dumps"

# Check if directories exist and are not empty
if [ -d "${GLPI_DIR}" ] && [ "$(ls -A ${GLPI_DIR})" ]; then
    echo "Compressing GLPI directory: ${GLPI_DIR}..."
    tar czf "${GLPI_BACKUP_FILE}" ${EXCLUDES} ${GLPI_DIR} 2>/dev/null
else
    echo "Directory ${GLPI_DIR} is empty or does not exist."
fi

if [ -d "${GLPI_DATA_DIR}" ] && [ "$(ls -A ${GLPI_DATA_DIR})" ]; then
    echo "Compressing GLPI data directory: ${GLPI_DATA_DIR}..."
    tar czf "${GLPI_BACKUP_DATA_FILE}" ${EXCLUDES} ${GLPI_DATA_DIR} 2>/dev/null
else
    echo "Directory ${GLPI_DATA_DIR} is empty or does not exist."
fi

# Inform about the completion of directory backups
echo "Directory backups completed."
echo "Files created:"
echo "GLPI directory: ${GLPI_BACKUP_FILE}"
echo "GLPI data directory: ${GLPI_BACKUP_DATA_FILE}"

echo "Starting database backup..."

# Database backup
echo "Dumping database ${DB_NAME}..."
mysqldump -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" | gzip > "${DB_BACKUP_FILE}"

# Inform about the completion of the database backup
echo "Database backup completed. File created: ${DB_BACKUP_FILE}"

echo "Starting cleanup of old backups..."

# Cleanup old backups
echo "Removing backups older than ${BACKUP_RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -type f -name 'glpi_dir_backup_*.tar.gz' -mtime +${BACKUP_RETENTION_DAYS} -exec rm {} \;
find "${BACKUP_DIR}" -type f -name 'glpi_data_backup_*.tar.gz' -mtime +${BACKUP_RETENTION_DAYS} -exec rm {} \;
find "${BACKUP_DIR}" -type f -name 'glpi_db_backup_*.sql.gz' -mtime +${BACKUP_RETENTION_DAYS} -exec rm {} \;

# Inform about the completion of cleanup
echo "Old backup cleanup completed."

echo "All actions completed successfully."
