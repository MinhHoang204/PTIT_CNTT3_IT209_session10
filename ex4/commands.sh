#!/bin/bash
set -e  # Dừng script nếu có lệnh nào đó bị lỗi

echo "=============================================="
echo "[1/6] Tạo Custom Bridge Network tên app-net"
echo "=============================================="
docker network create app-net

echo "=============================================="
echo "[2/6] Tạo Named Volume tên db-data"
echo "=============================================="
docker volume create db-data

echo "=============================================="
echo "[3/6] Khởi chạy Database Container (postgres:15-alpine)"
echo "=============================================="
docker run -d \
  --name db-server \
  --network app-net \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  -v db-data:/var/lib/postgresql/data \
  postgres:15-alpine

echo "=============================================="
echo "[4/6] Khởi chạy Backend Container tham gia app-net"
echo "=============================================="
docker run -d \
  --name app-container \
  --network app-net \
  -p 8080:3000 \
  -e PORT=3000 \
  -e DB_HOST=db-server \
  -e DB_USER=admin \
  -e DB_PASSWORD=secret \
  -e DB_NAME=mydb \
  hw-backend:v1

echo "=============================================="
echo "[5/6] Chờ 10 giây để các container khởi động hoàn tất"
echo "=============================================="
sleep 10

echo "=============================================="
echo "[6/6] Kiểm tra kết nối từ Backend đến Database qua tên db-server"
echo "=============================================="
docker exec -it app-container ping -c 2 db-server

echo ""
echo " Hoàn tất! Kiểm tra các tài nguyên đã tạo:"
echo "  - Network:  docker network ls | grep app-net"
echo "  - Volume:   docker volume ls | grep db-data"
echo "  - Inspect:  docker network inspect app-net"
echo "  - Containers: docker ps"
