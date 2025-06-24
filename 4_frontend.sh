#!/bin/bash
set -e

read -p "Введите IP ВМ1 (backend): " BACKEND1
read -p "Введите IP ВМ2 (backend): " BACKEND2

echo "[1/5] Установка Nginx..."
sudo apt update
sudo apt install -y nginx docker.io docker-compose

echo "[2/5] Создание конфигурации балансировщика..."
cat <<EOF | sudo tee /etc/nginx/sites-available/load_balancer
upstream backend {
    server $BACKEND1:5000;
    server $BACKEND2:5000;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /nginx_status {
        stub_status;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

echo "[3/5] Активация конфигурации..."
sudo ln -sf /etc/nginx/sites-available/load_balancer /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo "[4/5] Запуск nginx-prometheus-exporter в Docker..."
docker run -d \
  --name nginx_exporter \
  -p 9113:9113 \
  --network=host \
  nginx/nginx-prometheus-exporter:latest \
  -nginx.scrape-uri http://127.0.0.1/nginx_status

echo "[5/5] Готово!"
echo "Nginx балансирует трафик между $BACKEND1:5000 и $BACKEND2:5000"
echo "Метрики Nginx Exporter доступны на http://localhost:9113/metrics"
