// lib/models/sos_alert_model.dart

class SOSAlertModel {
  final String id;
  final String name;
  final String phone;
  final double latitude;
  final double longitude;
  final String status; // 'critical', 'warning', 'safe'
  final String? message; // Lời nhắn
  final String? waterLevel; // 'Thấp', 'Trung bình', 'Khẩn cấp'
  final String? peopleCount; // Số người
  final DateTime? createdAt; // Thời gian tạo

  SOSAlertModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.message,
    this.waterLevel,
    this.peopleCount,
    this.createdAt,
  });

  // Factory để chuyển đổi dữ liệu JSON từ Server thành Object Dart
  factory SOSAlertModel.fromJson(Map<String, dynamic> json) {
    return SOSAlertModel(
      id: json['_id'] ?? json['id'] ?? '',

      // Map các trường tên có thể có từ Server
      name: json['name'] ?? json['fullName'] ?? 'Người dùng ẩn danh',
      phone: json['phone'] ?? 'Không có SĐT',

      // Xử lý tọa độ an toàn (chuyển sang double)
      latitude: double.tryParse(
              json['latitude']?.toString() ?? json['lat']?.toString() ?? '0') ??
          0.0,
      longitude: double.tryParse(json['longitude']?.toString() ??
              json['lon']?.toString() ??
              '0') ??
          0.0,

      status: json['status'] ?? 'pending',
      message: json['message'] ?? '',

      // Map trường mức nước (Server có thể trả về 'water_level' hoặc 'waterLevel')
      waterLevel: json['water_level'] ?? json['waterLevel'] ?? 'Chưa rõ',

      // Map trường số người
      peopleCount: json['people_count']?.toString() ??
          json['peopleCount']?.toString() ??
          '?',

      // Xử lý thời gian
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : DateTime.now(),
    );
  }
}
