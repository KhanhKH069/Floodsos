# 📱 FloodSOS Flutter App

Ứng dụng di động dành cho người dân và lực lượng cứu hộ trong tình huống lũ lụt khẩn cấp, được thiết kế theo giao diện **Calm Crisis**.

## ✨ Tính Năng Nổi Bật
- Giao diện tối mờ (Glassmorphism) thân thiện ban đêm và dưới trời mưa.
- Gửi tín hiệu SOS khẩn cấp (GPS + Voice Record).
- Chỉ dẫn sơ tán (Self-Evacuation) và luồng cứu hộ (Rescue Dispatch) thông minh dựa trên AI dự báo ngập.
- Chatbot hỗ trợ thông tin nhanh.
- Cảnh báo thời tiết tự động.

## 🛠️ Yêu Cầu
- Flutter SDK `^3.0.0`
- Dart SDK `^3.0.0 <4.0.0`

## ⚙️ Cấu Hình Môi Trường (.env)
Dự án sử dụng `flutter_dotenv` để quản lý URL kết nối tới Backend nhằm bảo mật và dễ thay đổi môi trường.
**BẮT BUỘC:** Bạn phải tạo file `.env` tại thư mục root của `frontend-flutter` (cùng vị trí với `pubspec.yaml`).

Tạo file `.env` với nội dung sau:
```env
# Backend Server URL
# iOS Simulator / Web / Desktop:
BACKEND_URL=http://127.0.0.1:3002

# Nếu chạy trên Android Emulator (mặc định trỏ IP máy chủ):
# BACKEND_URL=http://10.0.2.2:3002

# OpenWeatherMap API Key
OWM_API_KEY=your_openweather_api_key
```

## 🚀 Hướng Dẫn Chạy

1. Tải các dependencies (chỉ dùng `dio` làm client mạng):
```bash
flutter pub get
```

2. Chạy ứng dụng:
```bash
# Cho dev testing trên desktop/web
flutter run -d windows
# Cho emulator / device thật
flutter run
```

3. Build file APK:
```bash
flutter build apk --release
```
