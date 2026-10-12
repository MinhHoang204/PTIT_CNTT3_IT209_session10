# Sử dụng base image Node.js 18 bản Alpine nhẹ
FROM node:18-alpine

# Thiết lập thư mục làm việc bên trong container
WORKDIR /app

# Copy file package.json và package-lock.json (nếu có) để cài dependencies trước
COPY package*.json ./

# Cài đặt các dependencies cần thiết
RUN npm install --production

# Copy toàn bộ mã nguồn ứng dụng vào container
COPY . .

# Khai báo biến môi trường PORT
ENV PORT=3000

# Mở cổng 3000 cho ứng dụng
EXPOSE 3000

# Chạy ứng dụng bằng exec form
CMD ["node", "server.js"]