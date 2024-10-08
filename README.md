## Backup Script for GLPI

This repository contains a script for automating backups of GLPI (Free IT Asset Management). The script is designed to create backups of both the GLPI database and files, ensuring that your data is secure and can be restored if necessary.

## Prerequisites

Before using the backup script, ensure you have the following:

- **GLPI Installation**: GLPI must be properly installed and configured on your server.
- **MySQL/MariaDB**: A database system compatible with GLPI.
- **Root Access**: You need root or sudo access to set up the system.

## Creating a Backup User

For added security, **do not run the script as root**. Instead, create a dedicated user to perform the backups.

**1. Create a new user (replace `backupuser` with your desired name):**

```bash
sudo adduser backupuser
```

**2. Grant permissions to the new user to access the necessary directories:**

```bash
sudo chown -R backupuser:backupuser /var/www/html/glpi /var/lib/glpi
```

**3. Add the user to the sudo group to allow the execution of necessary commands:**

```bash
sudo usermod -aG sudo backupuser
```

## Configuration

**1. Clone the Repository**

Clone the repository to your server with the command:

```bash
git clone https://github.com/allanlopesprado/glpi-backup.git
```

**2. Move the Configuration File**  
Move the configuration file to the appropriate directory with the command:

```bash
mv glpi-backup /var/
```

**3. Edit the Configuration File**
Open the configuration file for editing with the command:

```bash
sudo nano /var/glpi-backup/glpi-backup.conf
```

**4. Adjust the settings as needed**

Directory Paths
```bash
GLPI_DIR="/var/www/glpi"
GLPI_DATA_DIR="/var/lib/glpi"
GLPI_LOG_DIR="/var/log/glpi"
```

**Database**
```bash
DB_HOST="localhost"
DB_NAME="glpi"
DB_USER="user"
DB_PASS="password"
```
Backup
```bash
BACKUP_RETENTION_DAYS=5
```

Ensure that all paths and credentials are correct and match your GLPI configuration.

## Permissions
Ensure that the script and configuration files have the correct permissions:

**1. Set Permissions on the Configuration File**
Ensure that the configuration file is readable only by the root user and the script with the command:

```bash
sudo chmod 640 /var/glpi-backup/glpi-backup.sh
```

**2. Configure Directory Permissions**

Make sure to create the backup directory and that it has the correct permissions for the script to write with the following commands:

```bash
sudo chown backupuser:backupuser /var/glpi-backup/
sudo chmod 750 /var/glpi-backup/
```

**3. Set Permissions on the Script**
Grant execution permissions to the script with the command:

```bash
sudo chmod +x /var/glpi-backup/glpi-backup.sh
```

## Executar o Script Manualmente

To run the script manually, use the command:

```bash
cd /var/glpi-backup/
sudo ./glpi-backup.sh
```

The script will create a backup of the GLPI database and files. The progress and results will be logged in **/var/log/glpi/backup.log**

## Schedule Automatic Backups

To schedule the script to run automatically, use cron. Open the crontab for editing with the command:

```bash
sudo crontab -e
```

Add the following line to run the script daily at 2 AM:

```bash
0 2 * * * /var/glpi-backup/glpi-backup.sh
```

This ensures that the backup is performed automatically every day.

## Script Details
- **Backup Creation:** The script creates a dump of the GLPI database and compresses it. It also archives the GLPI files, excluding the backup and upload directories to avoid duplication. The files are stored in the directory: **/var/lib/glpi/_dumps and /var/lib/glpi/_uploads**.
- **Log File:** The script operations are logged in **/var/log/glpi/backup.log**. Check this file to monitor backup status and for troubleshooting any issues.
- **Error Handling:** If any operation fails, the script will exit and log an error. This includes failures in backup creation, permission issues, and configuration errors.

## Troubleshooting

If you encounter issues using the script, check the following:
- **Permissions:** Ensure that the script and backup directories have the correct permissions.
- **Database Credentials:** Verify that the database credentials are correct in the configuration file.
- **Disk Space:** Ensure there is sufficient disk space to store backups.
- **Logs:** Refer to the log file **/var/log/glpi/backup.log** for details on any errors or issues encountered.

## License

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

This software is licensed under the terms of GPLv2+, see LICENSE file for
details.
