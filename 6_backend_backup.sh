#!/bin/bash
set -e

# === Параметры ===
BACKUP_SCRIPT="/opt/backup_app.sh"
BACKUP_DIR="/opt/backups/app"
LOG_FILE="/var/log/app_backup.log"
CRON_TIME="0 3 * * *"

echo "[1/5] Установка зависимостей"
sudo apt update
sudo apt install -y rsync

echo "[2/5] Создание директории для бэкапов приложения: $BACKUP_DIR"
sudo mkdir -p "$BACKUP_DIR"
sudo chown "$USER":"$USER" "$BACKUP_DIR"

echo "[3/5] Развёртывание скрипта бэкапа приложения в $BACKUP_SCRIPT"
cat <<'EOF' | sudo tee "$BACKUP_SCRIPT" > /dev/null
#!/bin/bash
set -e

# === Конфигурация ===
BACKUP_DIR="/opt/backups/app"
TIMESTAMP=$(date +%F_%H-%M-%S)

# IP-адреса backend-серверов
declare -A HOSTS
HOSTS=(
  ["web1"]="192.168.0.239"
  ["web2"]="192.168.0.166"
)

mkdir -p "$BACKUP_DIR"

for NAME in "${!HOSTS[@]}"; do
  IP="${HOSTS[$NAME]}"
  DEST="$BACKUP_DIR/$NAME/$TIMESTAMP"

  echo "[INFO] Бэкап с $IP в $DEST"
  mkdir -p "$DEST"

  rsync -az -e ssh "user@$IP:/app/" "$DEST/"

  if [ $? -eq 0 ]; then
    echo "[OK] Успешно: $NAME ($IP)"
  else
    echo "[ERR] Ошибка при бэкапе $NAME ($IP)"
  fi
done
EOF

echo "[4/5] Делаем скрипт исполняемым..."
sudo chmod +x "$BACKUP_SCRIPT"

echo "[5/5] Добавление в cron (ежедневно в 3:00)..."
CRON_JOB="$CRON_TIME $BACKUP_SCRIPT >> $LOG_FILE 2>&1"
( crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT" ; echo "$CRON_JOB" ) | crontab -

echo "✅ Установка завершена!"
echo "⏰ Cron: ежедневно в 3:00"
echo "📁 Бэкапы: $BACKUP_DIR"
echo "🗂️ Лог: $LOG_FILE"
