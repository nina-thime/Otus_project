#!/bin/bash
set -e

# === Параметры ===
BACKUP_SCRIPT="/opt/backup_replica.sh"
BACKUP_DIR="/opt/backups/db"
LOG_FILE="/var/log/db_backup.log"
CRON_TIME="0 2 * * *"

# IP или хосты серверов с MySQL
DB_HOSTS=("192.168.0.239" "192.168.0.166")

# Пользователь SSH и MySQL
SSH_USER="user"
DB_USER="replica"
DB_PASS="replpass"

echo "[1/4] Создание директории для резервных копий: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo chown "$USER":"$USER" "$BACKUP_DIR"

echo "[2/4] Развёртывание скрипта бэкапа на балансировщике в $BACKUP_SCRIPT"
cat <<EOF | sudo tee "$BACKUP_SCRIPT" > /dev/null
#!/bin/bash
set -e

BACKUP_DIR="$BACKUP_DIR"
TIMESTAMP=\$(date +%F_%H-%M-%S)
REMOTE_BACKUP_DIR="/tmp/db_backup_\$TIMESTAMP"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
SSH_USER="$SSH_USER"
DB_HOSTS=(${DB_HOSTS[@]})

mkdir -p "\$BACKUP_DIR/\$TIMESTAMP"

for HOST in "\${DB_HOSTS[@]}"; do
  echo "[INFO] Начинаем бэкап с сервера \$HOST"

  # Создать бэкап на удалённом сервере
  ssh "\$SSH_USER@\$HOST" "mkdir -p \$REMOTE_BACKUP_DIR && mysqldump -u\$DB_USER -p\$DB_PASS --all-databases > \$REMOTE_BACKUP_DIR/alldb.sql"

  # Скопировать бэкап на балансировщик
  rsync -az --remove-source-files "\$SSH_USER@\$HOST:\$REMOTE_BACKUP_DIR/" "\$BACKUP_DIR/\$TIMESTAMP/\$HOST/"

  # Удалить временную папку на удалённом сервере
  ssh "\$SSH_USER@\$HOST" "rm -rf \$REMOTE_BACKUP_DIR"

  echo "[OK] Бэкап с \$HOST завершён"
done

echo "[DONE] Все бэкапы сохранены в \$BACKUP_DIR/\$TIMESTAMP"
EOF

echo "[3/4] Делаем скрипт исполняемым..."
sudo chmod +x "$BACKUP_SCRIPT"

echo "[4/4] Добавляем запуск в cron (ежедневно в 2:00)..."
CRON_JOB="$CRON_TIME $BACKUP_SCRIPT >> $LOG_FILE 2>&1"
( crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT" ; echo "$CRON_JOB" ) | crontab -

echo "✅ Установка завершена!"
echo "⏰ Cron: ежедневно в 2:00"
echo "📁 Бэкапы: $BACKUP_DIR"
echo "🗂️ Лог: $LOG_FILE"
