# 🌊 FloodSOS - Hệ Thống Cứu Hộ Lũ Lụt Thông Minh
> Ứng dụng cứu hộ khẩn cấp kết hợp AI, GPS, mạng nội bộ P2P và dữ liệu thời tiết thực để hỗ trợ người dân trong tình huống lũ lụt. Đạt chuần **Production-Ready** với tính năng sinh tồn offline cao cấp.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com)

---

## 📋 Mục Lục

- [Giới Thiệu](#-giới-thiệu)
- [Tính Năng Đột Phá](#-tính-năng-đột-phá)
- [Giao Diện Calm Crisis](#-giao-diện-calm-crisis)
- [Công Nghệ Sử Dụng](#-công-nghệ-sử-dụng)
- [Cấu Trúc Dự Án](#-cấu-trúc-dự-án)
- [Yêu Cầu Hệ Thống](#-yêu-cầu-hệ-thống)
- [Cài Đặt](#-cài-đặt)
- [Khởi Chạy Ứng Dụng](#-khởi-chạy-ứng-dụng)
- [API Endpoints](#-api-endpoints)

---

## 🎯 Giới Thiệu

**FloodSOS** là một hệ thống cứu hộ toàn diện được thiết kế để hỗ trợ người dân trong tình huống lũ lụt khẩn cấp. Ứng dụng không chỉ giải quyết bài toán thông tin khi có mạng, mà còn là một **công cụ sinh tồn** khi hạ tầng viễn thông tê liệt cục bộ.

---

## ✨ Tính Năng Đột Phá (Core Value)

### 🔴 Tính Sinh Tồn Ngoại Tuyến (Offline Resilience) - Khác biệt lớn nhất
*   **P2P UDP Mesh Network:** Tự động chuyển qua phát sóng sóng vị trí qua mạng LAN nội bộ nội phương khi sập mạng viễn thông. Điện thoại Admin biến thành "Trạm Radar Cứu hộ" dò tìm nạn nhân trong bán kính gần mà không cần Internet.
*   **Offline AI Routing (Thuật toán A*):** Tích hợp nhân AI thông minh ngay trên máy (local db ~5MB) để tự tìm đường chạy lũ, né các vùng ngập lụt nguy cấp, tính toán luồng cứu hộ không độ trễ, không tải mạng.
*   **Bản tin Thời tiết & Cache thông minh:** Giao diện hiển thị Biểu đồ cột (Bar Chart) mưa 24h & Radar mây vệ tinh. Khi mất mạng, app tự lôi bản Cache cũ ra để hiển thị thay vì lỗi trắng màn hình.

### 🟢 Dành cho Người Dùng
- ✅ Trạm phát tín hiệu SOS Pulse tự động với GPS & Voice Record.
- ✅ Lắng nghe cảnh báo thời tiết với radar mưa trực tiếp.
- ✅ Tương tác với hệ thống Chatbot hotline thông minh.

### 🔵 Dành cho Đội Cứu Hộ (Admin)
- ✅ Dashboard Realtime sử dụng Socket.IO theo dõi chuyển động cứu hộ.
- ✅ Bản đồ Admin tích hợp 2 luồng dữ liệu song song (Online từ Server & Offline từ UDP Mesh).
- ✅ Quản lý cảnh báo SOS tập trung.

---

## 🌊 Giao Diện Calm Crisis (Mobile)

Ứng dụng Flutter được thiết kế theo concept **Calm Crisis**:
- **Phong cách Glassmorphism:** Các dialog và thẻ được phủ kính mờ nhẹ trên nền đại dương sâu.
- **Ocean & Teal Palette:** Sử dụng gradient chủ đạo (`#0D1B2A` → `#1F3A4B`) và accent (`#00BCD4`).
- Tối ưu hóa UI/UX đi theo chuẩn Zero warnings của cộng đồng Flutter lints hiện đại.

---

## 🛠️ Công Nghệ Sử Dụng

### Frontend (Mobile)
- **Flutter / Dart** (Clean Architecture)
- Quản lý state bằng **Provider**
- Bản đồ: **flutter_map** kết hợp TileLayer của OpenWeatherMap
- Giao tiếp thời gian thực: **Socket.io_client** & **UDP Socket** (dart:io)
- Dữ liệu ngoại tuyến: **SharedPreferences**, **Sqflite**

### Backend
- **Node.js** & **Express.js**
- Web Sockets bằng **Socket.IO**
- Cơ sở dữ liệu NoSQL: **MongoDB**
- Xử lý file: **Multer**

---

## 📁 Cấu Trúc Dự Án

```
FloodSOS-Complete/
│
├── 📱 frontend-flutter/          # Ứng dụng Flutter (Calm Crisis UI)
│   ├── lib/
│   │   ├── config/             # Cấu hình màu sắc, Theme
│   │   ├── models/             # Định nghĩa Object
│   │   ├── providers/          # Quản lý State phân tán
│   │   ├── screens/            # Các trang giao diện
│   │   ├── services/           # Vi dịch vụ (UDP, Sockets, AI, API...)
│   │   └── widgets/            # Thành phần tái sử dụng (BarChart, Glass...)
│   ├── pubspec.yaml            # Thư viện
│   └── .env                    # Thông số kết nối API/Backend
│
└── 🔧 sos-backend/               # Server Node.js
    ├── server.js                 # API Core & Sockets
    └── package.json
```

---

## 💻 Yêu Cầu Hệ Thống

| Công Cụ | Phiên Bản | Link Tải |
|---------|-----------|----------|
| **Flutter SDK** | ≥ 3.0.0 | [flutter.dev/install](https://docs.flutter.dev/install/archive) |
| **Node.js** | ≥ 14.x | [nodejs.org](https://nodejs.org/) |
| **MongoDB** | ≥ 4.x | [mongodb.com](https://www.mongodb.com/try/download/community) |

---

## 🚀 Cài Đặt và Khởi Chạy

### 1. Cấu hình Backend (Node.js)

```bash
cd sos-backend
npm install
npm start
```
*Server mặc định chạy tại: `http://localhost:3002`.*

### 2. Cấu hình Frontend (Flutter)

Tạo file `.env` tại thư mục root của `frontend-flutter`:
```env
BACKEND_URL=http://10.0.2.2:3002   # Dành cho Emulator (Web/Desktop: 127.0.0.1)
OWM_API_KEY=YOUR_OPENWEATHER_KEY # Key dự báo thời tiết và radar
```

Khởi chạy ứng dụng:
```bash
cd frontend-flutter
flutter clean && flutter pub get
flutter run
```

---

## 📡 Chức năng Backend (Phụ trợ)

- **RESTful API**: Hỗ trợ POST/GET/DELETE danh sách SOS, Upload Audio Voice SOS, Auth, và OpenWeather Proxy.
- **WebSocket (Socket.io)**: Phát sóng sự kiện tạo mớI/cập nhật vị trí SOS trong chớp mắt.

---

> 🎉 Dự án đạt chất lượng **0 Warning** từ công cụ `flutter analyze`, được tối ưu hoàn toàn cho các ứng dụng đi báo cáo, nghiệm thu hay pitching tại các cuộc thi Đổi mới Sáng tạo.

**Tác giả:** Khanh Vu - [GitHub](https://github.com/KhanhKH069)