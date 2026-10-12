# Bài 4: Thiết lập Custom Network & Named Volume bằng Docker CLI
## Giới thiệu
Kết nối cụm 2 container (Backend Web API + PostgreSQL Database) bằng Docker CLI thủ công, sử dụng Custom Bridge Network để 
giao tiếp nội bộ qua tên service và Named Volume để lưu trữ dữ liệu bền vững.

## Kiến trúc
- **app-net**: Custom Bridge Network - cho phép các container giao tiếp qua tên service (DNS resolution)
- **db-data**: Named Volume - lưu trữ dữ liệu PostgreSQL tồn tại độc lập với vòng đời container
- **db-server**: Container PostgreSQL 15 Alpine, mount volume `db-data` vào `/var/lib/postgresql/data`
- **app-container**: Container Backend Web API, kết nối DB qua hostname `db-server`

## Các bước thực hiện
### 1. Cấp quyền thực thi cho script
```bash
chmod +x commands.sh
```

### 2. Chạy script
```bash
./commands.sh
```

### 3. Kiểm tra kết quả
```bash
# Kiểm tra network đã tạo
docker network ls | grep app-net

# Kiểm tra volume đã tạo
docker volume ls | grep db-data

# Kiểm tra chi tiết network
docker network inspect app-net

# Kiểm tra DNS resolution: ping db-server từ backend container
docker exec -it app-container ping -c 2 db-server

# Kiểm tra trạng thái container
docker ps
```