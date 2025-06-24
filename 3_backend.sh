#!/bin/bash
set -e

echo "[1/5] Установка системных зависимостей..."
sudo apt update
sudo apt install -y python3 python3-pip mariadb-client docker.io
sudo python3 -m pip install --break-system-packages flask prometheus-flask-exporter mysql-connector-python

echo "[2/5] Создание Flask-приложения..."
sudo mkdir -p /app

sudo tee /app/app.py > /dev/null <<'EOF'
from flask import Flask, request
from datetime import datetime
from prometheus_flask_exporter import PrometheusMetrics
import socket
import mysql.connector
import os

app = Flask(__name__)
metrics = PrometheusMetrics(app)

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "ninaweb")
DB_PASS = os.getenv("DB_PASS", "ninapass")
DB_NAME = os.getenv("DB_NAME", "nina_db")

def log_to_db(client_ip):
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME
        )
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO logs (timestamp, client_ip, host) VALUES (NOW(), %s, %s)",
            (client_ip, socket.gethostname())
        )
        conn.commit()
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"DB Error: {e}")

@app.route('/')
def home():
    client_ip = request.remote_addr
    log_to_db(client_ip)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return (
        f"<h1>Время: {now}</h1>"
        f"<h2>IP клиента: {client_ip}</h2>"
        f"<h2>Хост: {socket.gethostname()}</h2>"
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

echo "[3/5] Настройка systemd-сервиса Flask..."
sudo tee /etc/systemd/system/flaskapp.service > /dev/null <<EOF
[Unit]
Description=Flask App with Prometheus and MySQL Logging
After=network.target mariadb.service

[Service]
User=root
WorkingDirectory=/app
ExecStart=/usr/bin/env python3 /app/app.py
Environment=DB_HOST=localhost
Environment=DB_USER=ninaweb
Environment=DB_PASS=ninapass
Environment=DB_NAME=nina_db
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable flaskapp
sudo systemctl start flaskapp

echo "[4/5] Запуск mysqld_exporter в Docker..."
docker run -d \
  --name mysqld_exporter \
  -e DATA_SOURCE_NAME="exporter:exporterpass@(localhost:3306)/" \
  -p 9104:9104 \
  prom/mysqld-exporter

echo "[5/5] Готово!"
echo "Flask-приложение доступно на порту 5000"
echo "Метрики MariaDB exporter доступны на http://IP_frontend:9104/metrics"
