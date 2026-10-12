# Bài 2: Đóng gói ứng dụng Web Backend bằng Single-stage Dockerfile
## Giới thiệu
Đóng gói ứng dụng REST API Node.js/Express thành Docker Image sử dụng Dockerfile Single-stage, triển khai lên môi trường 
chạy thử nghiệm.

## Cấu trúc dự án
- `Dockerfile`: Dockerfile single-stage
- `server.js`: Ứng dụng Express trả về JSON tại route `/`
- `package.json`: Khai báo dependencies (express ^4.18.2)
- `.dockerignore`: Loại bỏ file/thư mục không cần thiết khỏi build context

## Các bước thực hiện
### 1. Build image
```bash
docker build -t hw-backend:v1 .
```

### 2. Chạy container
```bash
docker run -d --name app-single-stage -p 8080:3000 hw-backend:v
```

### 3. Kiểm tra
```bash
docker ps
docker logs app-single-stage
curl -i http://localhost:8080/
```

**Kết quả:**
* Container có trạng thái Up
* Lệnh curl trả về mã HTTP 200 OK và response JSON:
```json
{"status":"success","message":"Hello from Docker Single-stage!"}
```

Giải thích Dockerfile:
* FROM node:18-alpine: Base image Node.js 18 bản Alpine, nhẹ và nhanh
* WORKDIR /app: Thư mục làm việc mặc định
* COPY package*.json ./: Copy file dependencies trước để tận dụng cache
* RUN npm install --production: Cài đặt dependencies production
* COPY . .: Copy toàn bộ mã nguồn
* ENV PORT=3000: Khai báo biến môi trường
* EXPOSE 3000: Mở cổng 3000
* CMD ["node", "server.js"]: Lệnh khởi động exec form