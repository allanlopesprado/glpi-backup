## Script de Backup para GLPI

Este repositório contém um script para realizar backups automatizados do GLPI (Gestor Livre de Parque Informático). O script foi projetado para criar backups do banco de dados e dos arquivos do GLPI, garantindo que seus dados estejam seguros e possam ser restaurados se necessário.

## Pré-requisitos

Antes de usar o script de backup, certifique-se de que você possui o seguinte:

- **Instalação do GLPI**: O GLPI deve estar instalado e configurado corretamente no seu servidor.
- **MySQL/MariaDB**: Um sistema de banco de dados compatível com o GLPI.
- **Acesso Root**: Você precisa de acesso root ou sudo para configurar o sistema.

## Criação de Usuário para Backup

Para maior segurança, **não execute o script como root**. Em vez disso, crie um usuário dedicado para executar os backups. 

### 1. Crie um novo usuário (substitua `backupuser` pelo nome desejado):

```bash
sudo adduser backupuser
```

### 2. Conceda permissões ao novo usuário para acessar os diretórios necessários:

```bash
sudo chown -R backupuser:backupuser /var/www/glpi /etc/glpi /var/lib/glpi /var/log/glpi
```

### 3. Adicione o usuário ao grupo sudo para permitir a execução de comandos necessários:

```bash
sudo usermod -aG sudo backupuser
```

## Configuração

### 1. Clone o Repositório

Clone o repositório em seu servidor com o comando:

```bash
git clone https://github.com/allanlopesprado/backup-glpi.git
cd Backup-GLPI
```

### 2. Crie o Arquivo de Configuração
Copie o arquivo de configuração de exemplo para o diretório apropriado com o comando:

```bash
sudo cp backup-glpi.conf.example /etc/backup-glpi.conf
```

### 3. Edite o Arquivo de Configuração
Abra o arquivo de configuração para edição com o comando:

```bash
sudo nano /etc/backup-glpi.conf
```

### 4. Ajuste as configurações conforme necessário


Diretórios
```bash
GLPI_DIR="/var/www/glpi"
GLPI_CONFIG_DIR="/etc/glpi"
GLPI_DATA_DIR="/var/lib/glpi"
GLPI_LOG_DIR="/var/log/glpi"
```

Banco de Dados
```bash
DB_HOST="localhost"
DB_NAME="glpi"
DB_USER="seuusuario"
DB_PASS="suasenha"
```
Backup
```bash
BACKUP_RETENTION_DAYS=5
```

Certifique-se de que todos os caminhos e credenciais estão corretos e correspondem à sua configuração do GLPI.

## Permissões
Certifique-se de que o script e os arquivos de configuração tenham as permissões corretas:

### 1. Defina Permissões no Script
Conceda permissões de execução ao script com o comando:

```bash
sudo chmod +x backup-glpi.sh
```

### 2. Defina Permissões no Arquivo de Configuração
Certifique-se de que o arquivo de configuração seja legível apenas pelo usuário root e pelo script com o comando:

```bash
sudo chmod 640 /etc/backup-glpi.conf
```

### 3. Configure Permissões de Diretórios
Certifique-se de que o diretório de backup tenha as permissões corretas para que o script possa escrever com os seguintes comandos:

```bash
sudo chown backupuser:backupuser /var/backups/glpi
sudo chmod 750 /var/backups/glpi
```
## Executar o Script Manualmente

Para executar o script manualmente, use o comando:

```bash
sudo ./backup-glpi.sh
```

O script criará um backup do banco de dados e dos arquivos do GLPI. O progresso e os resultados serão registrados em **/var/log/glpi/backup.log**

## Agendar Backups Automáticos

Para agendar o script para ser executado automaticamente, utilize o cron. Abra o crontab para edição com o comando:

```bash
sudo crontab -e
```

Adicione a seguinte linha para executar o script diariamente às 2 AM:

```bash
0 2 * * * /var/backups/glpi/backup-glpi.sh
```

Isso garante que o backup seja realizado automaticamente todos os dias.

## Detalhes do Script
- **Criação de Backup:** O script cria um dump do banco de dados GLPI e o comprime. Também arquiva os arquivos do GLPI, excluindo os diretórios de backup e upload para evitar duplicidade.
- **Arquivo de Log:** As operações do script são registradas em **/var/log/glpi/backup.log**. Verifique este arquivo para monitorar o status dos backups e para depuração em caso de problemas.
- **Tratamento de Erros:** Se qualquer operação falhar, o script sairá e registrará um erro no log. Isso inclui a falha na criação de backups, problemas com permissões e falhas na configuração.

## Solução de Problemas

Se você encontrar problemas ao usar o script, verifique o seguinte:
- **Permissões:** Certifique-se de que o script e os diretórios de backup têm as permissões corretas.
- **Credenciais do Banco de Dados:** Verifique se as credenciais do banco de dados estão corretas no arquivo de configuração.
- **Espaço em Disco:** Garanta que há espaço suficiente em disco para armazenar os backups.
- **Logs:** Consulte o arquivo de log **/var/log/glpi/backup.log** para detalhes sobre quaisquer erros ou problemas encontrados.

## Licença

Este script está licenciado sob a Licença Pública Geral GNU v3.0. Veja o arquivo **LICENSE** para mais detalhes.

## Contato
Para quaisquer problemas ou perguntas, por favor, abra uma issue em GitHub Issues ou entre em contato por e-mail: allanlopesprado@hotmail.com

