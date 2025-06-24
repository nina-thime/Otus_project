#!/bin/bash
set -e

echo "[1/6] Установка MariaDB..."
sudo apt update
sudo apt install -y mariadb-server

echo "[2/6] Настройка конфигурации MariaDB (master)..."
sudo sed -i '/^\[mysqld\]/a server-id=1\nlog_bin=mysql-bin\nbind-address=0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf

echo "[3/6] Перезапуск MariaDB..."
sudo systemctl restart mariadb

echo "[4/6] Создание базы данных и пользователей..."
sudo mariadb <<EOF
CREATE DATABASE IF NOT EXISTS nina_db;
USE nina_db;
CREATE TABLE IF NOT EXISTS logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME,
    client_ip VARCHAR(45),
    host VARCHAR(255)
);
CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'replpass';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
CREATE USER IF NOT EXISTS 'ninaweb'@'localhost' IDENTIFIED BY 'ninapass';
GRANT INSERT ON nina_db.* TO 'ninaweb'@'localhost';
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'exporterpass';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS;
EOF

echo "[5/6] ВАЖНО: Скопируйте результат команды ниже для настройки реплики:"
echo "    sudo mariadb -e 'SHOW MASTER STATUS\\G'"
echo "[6/6] После настройки реплики не забудьте выполнить:"
echo "    sudo mariadb -e 'UNLOCK TABLES;'"
