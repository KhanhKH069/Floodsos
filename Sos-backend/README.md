# 🔧 FloodSOS Backend API (Node.js/Express)

Phân hệ Backend xử lý dữ liệu trung tâm của ứng dụng cứu hộ FloodSOS. Backend cung cấp các RESTful API và đặc biệt là hệ thống **Socket.IO Real-time** để phục vụ việc chia sẻ tọa độ (Live Tracking) cho Đội Cứu Hộ và Người Dân.

## ✨ Tính Năng
- Cung cấp RESTful API cho quản lý SOS (Gửi SOS qua text, voice, tọa độ).
- Phát sóng dữ liệu Real-time sử dụng WebSocket (Socket.IO).
- Tương tác cơ sở dữ liệu MongoDB thông qua thư viện Mongoose.
- Xử lý file Upload an toàn với Multer.

## 🛠️ Yêu Cầu Cài Đặt
- Node.js `^14.x` trở lên
- MongoDB (Chạy ở Port `27017` mặc định)

## 🚀 Khởi Chạy Server

1. **Cài đặt thư viện:**
```bash
npm install
```

2. **Chạy Server:**
```bash
npm start
# Hoặc dùng nodemon để dev:
# npm run dev
```

*Server mặc định sẽ lắng nghe ở port `3002`. Nếu bạn đổi port, hãy nhớ cập nhật biến `BACKEND_URL` ở ứng dụng Flutter `frontend-flutter/.env`.*

## 📡 Các Endpoints API Chính

| Phương thức | Endpoint | URL Cấu trúc | Mô tả |
|----------|----------|------------|-------|
| `POST` | Thêm SOS | `/api/sos/voice` | Nhận FormData gồm vị trí, text, âm thanh |
| `GET` | Lấy danh sách SOS | `/api/sos` | Lấy toàn bộ SOS đang hoạt động |
| `PUT` | Hoàn tất cứu hộ | `/api/sos/:id/resolve` | Đánh dấu SOS đã được giải quyết |
| `DELETE` | Xoá SOS | `/api/sos/:id` | Xóa khỏi DB vĩnh viễn |
| `POST` | AI Routing Proxy | `/api/sos/route` | Lấy các gợi ý đường phân tích |

## ⚡ Socket.IO Channel Events

Hệ thống cung cấp kết nối thời gian thực cực nhanh với các Event sau:

- **Lắng nghe (Listen from Client):**
  - `update_location`: Client gửi tọa độ mới lên Server, Server sẽ re-broadcast lại cho quyền Admin theo dõi.

- **Phát sóng (Emit to Client):**
  - `admin_alert`: Nếu có SOS khẩn cấp, báo ngay lập tức.
  - `sos_created` / `sos_updated`: Báo hiệu UI của App Flutter tự động cập nhật mà không cần HTTP Request/Pull.

## Dữ Liệu Đầu Vào SOS (Multipart FormData)
Khi gọi `/api/sos/voice`, Client Flutter cần đóng gói các trường sau:
- `lat` (double)
- `lon` (double)
- `name` (string)
- `phone` (string)
- `water_level` (string, e.g. "Khẩn cấp")
- `people_count` (int)
- `audio` (file âm thanh ghi âm)
- `message` (string ghi chú thêm)
