#!/bin/bash

# -------------------------------------------------------------------------
# @Name: Backup-GLPI.sh
# @Version: 2.1.0
# @Date: 2024-08-01
# @Author: Allan Lopes Prado
# @License: GNU General Public License v3.0
# @Description: This script performs automatic backups for GLPI.
# --------------------------------------------------------------------------
# LICENSE
#
# backup-glpi.sh is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# backup-glpi.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------

# AUTOMATIC BACKUP FOR GLPI

# VARIABLES
GLPI_DIR="/var/www/glpi"
GLPI_CONFIG_DIR="/etc/glpi"
GLPI_DATA_DIR="/var/lib/glpi"
GLPI_LOG_DIR="/var/log/glpi"
GLPI_DUMPS="$GLPI_DATA_DIR/_dumps"
GLPI_LOGFILE="$GLPI_LOG_DIR/backup.log"
GLPI_DBCONFIG="$GLPI_CONFIG_DIR/config_db.php"

# Ensure GLPI directories exist
mkdir -p $GLPI_DUMPS
mkdir -p $GLPI_LOG_DIR

# CREDENTIALS DATABASE
GLPI_DBUSER=$(grep "dbuser" $GLPI_DBCONFIG | cut -d "'" -f 2)
GLPI_DBPASS=$(grep "dbpassword" $GLPI_DBCONFIG | cut -d "'" -f 2)

# GLPI VERSION
GLPI_VERSION=$(mysql -u$GLPI_DBUSER -p$GLPI_DBPASS -D glpi -N -B -e "SELECT value FROM glpi_configs WHERE name = 'version';")

# VARIABLES BACKUP
GLPI_DATE=$(date +%Y-%m-%d-%H-%M)
GLPI_DBNAME=$(grep "dbdefault" $GLPI_DBCONFIG | cut -d "'" -f 2)
GLPI_BACKUP_NAME="glpi-${GLPI_VERSION}-${GLPI_DATE}"

# Start backup process
echo "Starting backup..."
echo -e "$GLPI_DATE \tCreating mysqldump into $GLPI_DUMPS/${GLPI_BACKUP_NAME}.sql.gz ..." >> $GLPI_LOGFILE

# Backup database
mysqldump -u $GLPI_DBUSER -p$GLPI_DBPASS $GLPI_DBNAME | gzip > $GLPI_DUMPS/${GLPI_BACKUP_NAME}.sql.gz

# Backup files excluding certain directories
cd $GLPI_DIR
tar --exclude='files/_dumps/*' --exclude='files/_uploads/*' -zcf $GLPI_DATA_DIR/_uploads/${GLPI_BACKUP_NAME}.files.tar.gz files/

# Remove old backups
find $GLPI_DUMPS -type f -mtime +5 -exec rm -rf {} \;
find $GLPI_DATA_DIR/_uploads -type f -mtime +5 -exec rm -rf {} \;

echo "Backup completed successfully!"
exit 0
