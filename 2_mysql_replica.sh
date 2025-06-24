#!/bin/bash
set -e

read -p "Введите IP мастера (Backend1): " MASTER_IP
read -p "Введите лог-файл (из SHOW MASTER STATUS): " LOG_FILE
read -p "Введите позицию (из SHOW MASTER STATUS): " LOG_POS

echo "[1/4] Установка MariaDB..."
sudo apt update
sudo apt install -y mariadb-server

echo "[2/4] Настройка конфигурации MariaDB (replica)..."
sudo sed -i '/^\[mysqld\]/a server-id=2\nrelay-log=relay-bin\nbind-address=0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf

echo "[2.1] Перезапуск MariaDB..."
sudo systemctl restart mariadb

echo "[3/4] Настройка репликации..."
sudo mariadb <<EOF
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='${MASTER_IP}',
  MASTER_USER='replica',
  MASTER_PASSWORD='replpass',
  MASTER_LOG_FILE='${LOG_FILE}',
  MASTER_LOG_POS=${LOG_POS};
START SLAVE;
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'exporterpass';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
EOF

echo "[4/4] Проверка:"
echo "    sudo mariadb -e 'SHOW SLAVE STATUS\\G'"
