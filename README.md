# Backup Script for GLPI

This repository contains an automated shell script for backing up GLPI (Gestionnaire Libre de Parc Informatique). The script performs atomic backups of both the database and the application files, ensuring data integrity and security.

## Features

- **Atomic Operations:** Backups are created in a temporary directory and only moved to the final destination upon successful completion, preventing corrupted files.
- **Data Integrity:** Automatically generates SHA256 checksums for every backup artifact.
- **Secure Authentication:** Uses temporary configuration files for MySQL authentication to prevent password exposure in the process list.
- **Pre-flight Checks:** Validates disk space and dependencies before execution.
- **Retention Policy:** Automatically removes backups older than the configured number of days.
- **Locking Mechanism:** Prevents concurrent execution of the script.

## Prerequisites

Ensure the following dependencies are installed on your server:

- **GLPI**: Installed and properly configured.
- **MySQL/MariaDB**: Database server.
- **Core Utilities**: `tar`, `gzip`, `mysqldump`, `sha256sum`, `curl` (for notifications).
- **Root/Sudo Access**: Required for installation and setting permissions.

## Security Best Practice (Database User)

For added security, avoid using the root database user. Instead, create a dedicated MySQL user with specific privileges for backups.

1. Log into MySQL as root:
```bash
sudo mysql -u root -p
````

2.  Run the following commands to create the user and grant permissions:

<!-- end list -->

```sql
CREATE USER 'glpi_backup'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT SELECT, SHOW VIEW, RELOAD, REPLICATION CLIENT, EVENT, TRIGGER, LOCK TABLES ON *.* TO 'glpi_backup'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

3.  You will use these credentials (`glpi_backup` and the password chosen) in the configuration file later.

## Installation

It is recommended to install the script in standard system directories.

**1. Clone the Repository**

Clone the repository to your server:

```bash
git clone [https://github.com/allanlopesprado/glpi-backup.git](https://github.com/allanlopesprado/glpi-backup.git)
cd glpi-backup
```

**2. Install Configuration File**

Create the configuration directory and copy the config file:

```bash
sudo mkdir -p /etc/glpi
sudo cp glpi-backup.conf /etc/glpi/
```

**3. Install Script**

Copy the script to an executable path (e.g., /usr/local/bin):

```bash
sudo cp glpi-secure-backup.sh /usr/local/bin/glpi-backup
sudo chmod +x /usr/local/bin/glpi-backup
```

## Configuration

Edit the configuration file to match your environment:

```bash
sudo nano /etc/glpi/glpi-backup.conf
```

### Configuration Variables

**Directories**

  - `GLPI_DIR`: Path to your GLPI installation (e.g., `/var/www/html/glpi`).
  - `BACKUP_ROOT`: Directory where backups will be stored (e.g., `/var/lib/glpi-backups`).
  - `LOG_FILE`: Path to the log file.

**Database**

  - `DB_HOST`: Database host (usually `localhost`).
  - `DB_NAME`: GLPI database name.
  - `DB_USER`: The MySQL user created in the "Security Best Practice" section.
  - `DB_PASS`: The password for the MySQL user.

**System**

  - `RETENTION_DAYS`: Number of days to keep local backups.
  - `MIN_DISK_SPACE_MB`: Minimum free space required (in MB) to run the backup.

**Notifications (Optional)**

  - `WEBHOOK_URL`: URL for Slack/Discord/Teams webhooks.

## Security Permissions

To ensure security, restrict access to the configuration file so that only the root user can read the database credentials.

```bash
sudo chown root:root /etc/glpi/glpi-backup.conf
sudo chmod 600 /etc/glpi/glpi-backup.conf
```

## Usage

### Manual Execution

To run the backup manually, execute the command:

```bash
sudo /usr/local/bin/glpi-backup
```

You can check the logs to verify the process:

```bash
tail -f /var/log/glpi-backup/backup.log
```

### Automatic Scheduling (Cron)

To automate the backup, add an entry to the root crontab.

1.  Open crontab:

<!-- end list -->

```bash
sudo crontab -e
```

2.  Add the following line to run daily at 02:00 AM:

<!-- end list -->

```bash
0 2 * * * /usr/local/bin/glpi-backup >> /var/log/glpi-backup/cron.log 2>&1
```

## Troubleshooting

If the script fails, check the following:

  - **Disk Space:** The script will abort if free space is below `MIN_DISK_SPACE_MB`.
  - **Permissions:** Ensure the user running the script (usually root) has read access to `GLPI_DIR` and write access to `BACKUP_ROOT`.
  - **Database Credentials:** Verify the user and password in `/etc/glpi/glpi-backup.conf`.
  - **Logs:** Review `/var/log/glpi-backup/backup.log` for specific error codes.

## License

[](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

This software is licensed under the terms of GPLv2+, see LICENSE file for details.
