# 📱 FloodSOS Flutter App (Frontend Core)

Phân hệ di động khẩn cấp được phát triển trên nền tảng Flutter, với kiến trúc sạch, hoàn toàn không có lỗi static analysis (Zero Warnings) và theo chuẩn **Production-Ready**.

## ✨ Tính Năng Nổi Bật (High-Resilience)
- **Giao diện Calm Crisis:** Thiết kế kính mờ (Glassmorphism), UI tối giản, rõ ràng thân thiện dưới trời mưa bão.
- **Offline P2P UDP Mesh Network:** Khi sập mạng viễn thông, app vẫn dùng UDP Multicast để phát sóng SOS và vị trí sang điện thoại radar của Admin ở khoảng cách gần.
- **Local AI Offline Routing:** Thuật toán A* với dữ liệu đường xá thu gọn chạy 100% trên RAM điện thoại. Tính toán đường chạy lũ trong nháy mắt kể cả khi không có mạng.
- **Tracking Song Song:** Theo dõi vị trí đội cứu hộ vừa qua Socket.io (khi có mạng) vừa qua UDP Mesh (khi mất mạng).
- **Trạm Thời Tiết Ngoại Tuyến:** Tự động vẽ bản đồ Radar Mưa và Biểu đồ Cột. Khi mất mạng, app lấy dữ liệu Cache từ SQLite/SharedPrefs.
- **Admin Dashboard:** Tích hợp trực tiếp trên điện thoại người dùng có thẩm quyền.

## 🛠️ Yêu Cầu Hệ Thống
- Flutter SDK `^3.0.0`
- Dart SDK `^3.0.0 <4.0.0`
- Đề xuất chạy trên thiết bị thật để test đầy đủ bộ tính năng Hardware (Sensors, Microphone, UDP Sockets).

## ⚙️ Cấu Hình Môi Trường (.env)
**BẮT BUỘC:** Tạo file `.env` tại thư mục root của project `frontend-flutter` (cùng folder với thư mục `lib/` và file `pubspec.yaml`).

```env
# URL kết nối tới Backend (Node.js)
# iOS Simulator / Web / Desktop:
BACKEND_URL=http://127.0.0.1:3002
# Chạy trên Android Emulator:
# BACKEND_URL=http://10.0.2.2:3002

# OpenWeatherMap API Key (dùng cho Weather & Radar Map)
OWM_API_KEY=your_openweathermap_key
```

## 🚀 Hướng Dẫn Build & Chạy

1. Tải dependencies:
```bash
flutter clean && flutter pub get
```

2. Chạy ứng dụng:
```bash
# Cho dev testing trên desktop
flutter run -d windows

# Cho emulator / device thật kết nối
flutter run
```

3. Đóng gói Production:
```bash
# Build APK cho Android
flutter build apk --release

# Build EXE cho Windows
flutter build windows --release
```

*Lưu ý: Mọi print log đã được loại bỏ và thay bằng gói `app_logger.dart` để ghi log sạch sẽ chuẩn công nghiệp.*
