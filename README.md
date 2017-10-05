# Backup-GLPI
Este script foi desenvolvido para facilitar o backup local do sistema GLPI, assim como possibilitar uma copia segura na nuvem, para isso o sistema usa ferramenta https://rclone.org/, que deve ser instalada previamente em seu SO.

É necessario que o script seja criado em local de sua preferencia, no exemplo a pasta utilizada para armazenar o backup sera.

/var/www/html/glpi/scripts, onde é criado o arquivo backup-glpi.sh, e executado a permissão > chmod +x backup-glpi.sh

Após a instalação e configuração correta do rclone, você deve identificar a seguinte linha do backup.

- /usr/sbin/rclone sync /backup GoogleDrive:BackupGLPI >> $LOGFILE;

Onde deve alterar as seguintes informações.

Drive:RemoteFolder, no caso o driver criado foi GoogleDrive e pasta remota foi BackupGLPI.

Apos isto é necessario inserir a seguinte linha no crontab, usando o comando > crontab -e

#Backup GLPI
58 23 * * * root /var/www/html/glpi/scripts/backup-glpi.sh

Onde o backup sera executado todos os dias as 23:58. 


