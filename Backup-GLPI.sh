#!/bin/bash

# -------------------------------------------------------------------------
# @Name: Backup-GLPI.sh
#	@Version: 1.3.0
#	@Data: 26/03/2018
#	@Copyright: https://gist.github.com/allanlopesprado
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

# AUTOMATIC BACKUP FOR GLPI

# VARIABLES GLPI
GLPI_DIR="/var/www/html/glpi";
GLPI_DUMPS="$GLPI_DIR/files/_dumps";
GLPI_LOGFILE="$GLPI_DIR/files/_log/backup.log";
GLPI_DBCONFIG=`find $GLPI_DIR/config -name "config_db.php"`;

# CREDENTIALS DATABASE
GLPI_DBUSER=`grep "dbuser" $GLPI_DBCONFIG | cut -d "'" -f 2`;
GLPI_DBPASS=`grep "dbpassword" $GLPI_DBCONFIG | cut -d "'" -f2`;

# GLPI VERSION
var=$(mysql -u$GLPI_DBUSER -p$GLPI_DBPASS -D glpi -N -B -e "select value from glpi_configs where name like 'version';")

# VARIABLES BACKUP
GLPI_DATE=`date +%Y-%m-%d-%H-%m`;
GLPI_DBNAME=`grep "dbdefault" $GLPI_DBCONFIG | cut -d "'" -f 2`;
GLPI_VERSION="glpi-${var}-";
echo "Starting backup..."
echo -e "$GLPI_DATE \tCreating mysqldump into $GLPI_DUMPS/$GLPI_DATE.sqldump.sql ..." >> $GLPI_LOGFILE;
mysqldump -u $GLPI_DBUSER -p$GLPI_DBPASS $GLPI_DBNAME > $GLPI_DUMPS/$GLPI_VERSION$GLPI_DATE.sql.gz;
cd $GLPI_DIR 
tar --exclude='files/_dumps/*' --exclude='files/_uploads/*' -zcf $GLPI_DIR/files/_uploads/$GLPI_VERSION$GLPI_DATE.files.tar.gz files/;

# DELETE THE OLD BACKUPS
find $GLPI_DUMPS -type f -mtime +5 -exec rm -rf {} \;
find $GLPI_DIR/files/_uploads -type f -mtime +5 -exec rm -rf {} \;
echo "Backup Done!";
exit 0;
