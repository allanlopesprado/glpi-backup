#!/bin/bash

# -------------------------------------------------------------------------
# @Name: Backup-GLPI.sh
#	@Version: 1.1.0
#	@Data: 10/03/2017
#	@Copyright: https://gist.github.com/allanlopesprado
#	@Copyright: https://gist.github.com/JosefJezek
# --------------------------------------------------------------------------
# LICENSE
#
# Backup-GLPI.sh is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Backup-GLPI.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# If not, see <http://www.gnu.org/licenses/>.
# --------------------------------------------------------------------------

# Check directory
echo "Check directory, if it does not exist it will be created!"
if [ -e "/backup" ]
then
echo "Directory already exists.";
else
echo "Directory does not exist, creating directory."
mkdir /backup
fi

# Deleting old backups
echo "Deleting backups older than 7 days!";
find /backup -type f -mtime +6 -exec rm -rf {} \;
find /var/www/html/glpi/files/_dumps -type f -mtime +6 -exec rm -rf {} \;
echo "Deleting Done!";

# Backup script for GLPI
GLPI_DIR='/var/www/html/glpi';
BACKUP_DIR='/backup';
LOGFILE='/var/log/glpi/backup.log';

# Database credentials
DBUSER=root
DBPASS=root

# Checking GLPI version
var=$(mysql -u$DBUSER -p$DBPASS -D glpi -N -B -e "select value from glpi_configs where name like 'version';")

# Variables
DATE=`date +%Y-%m-%d-%H-%m`;
LOGTIME=`date +"%Y-%m-%d %H:%m"`;
DBCONFIG=`find $GLPI_DIR -name "config_db.php"`;
DBNAME=`grep "dbdefault" $DBCONFIG | cut -d "'" -f 2`;
GLPISIZE=`du -sh $GLPI_DIR`;
GLPIVERSION="glpi-${var}-";

# Starting Backup
echo "Starting backup..."
echo "ALERT: This may take several minutes, depending on the size of the backup!";
echo -e "$LOGTIME \t## New backup started ##" >> $LOGFILE;
echo -e "$LOGTIME \tCreating mysqldump into $BACKUP_DIR/$DATE.sqldump.sql ..." >> $LOGFILE;
mysqldump -u $DBUSER -p$DBPASS $DBNAME > $BACKUP_DIR/$GLPIVERSION$DATE.sql.gz;
echo -e "$LOGTIME \tpacking: $GLPISIZE.. into $BACKUP_DIR/$DATE.backup.tar.bz2 ..." >> $LOGFILE;
tar -cjPf $BACKUP_DIR/$GLPIVERSION$DATE.backup.tar.bz2 $GLPI_DIR $BACKUP_DIR/$GLPIVERSION$DATE.sql.gz >> $LOGFILE;

# Go back to original working directory.
echo -e "$LOGTIME \tAll done..." >> $LOGFILE;
echo "Backup done!";

# Copy dump to GLPI
echo "Copy dump to GLPI.";
cd /backup
cp -p *.sql.gz /var/www/html/glpi/files/_dumps
echo "Copy Done!";

# Upload backup Google Drive
echo "Upload backup Google Drive.";
echo "ALERT: This may take several minutes, depending on your upload speed!";
/usr/sbin/rclone sync /backup GoogleDrive:BackupGLPI >> $LOGFILE;
echo "Upload Done!";

exit 0;
