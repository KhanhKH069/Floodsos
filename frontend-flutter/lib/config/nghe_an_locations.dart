// lib/config/nghe_an_locations.dart
// 7 tọa độ thực tế tại tỉnh Nghệ An – dùng làm vị trí SOS mặc định
// khi thiết bị không thể lấy GPS (desktop / web / emulator)

import 'dart:math';

class NgheAnLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String district;

  const NgheAnLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.district,
  });

  @override
  String toString() => '$name ($district)';
}

class NgheAnLocations {
  /// 7 điểm tọa độ phân bố đều trên địa bàn tỉnh Nghệ An
  static const List<NgheAnLocation> points = [
    NgheAnLocation(
      name: 'TP. Vinh – Trung tâm hành chính',
      latitude: 18.6796,
      longitude: 105.6813,
      district: 'TP. Vinh',
    ),
    NgheAnLocation(
      name: 'Hoàng Mai – Cảng Đông Hồi',
      latitude: 19.2983,
      longitude: 105.7321,
      district: 'TX. Hoàng Mai',
    ),
    NgheAnLocation(
      name: 'Quỳnh Lưu – Thị trấn Cầu Giát',
      latitude: 19.1100,
      longitude: 105.5600,
      district: 'H. Quỳnh Lưu',
    ),
    NgheAnLocation(
      name: 'Diễn Châu – Thị trấn Diễn Châu',
      latitude: 18.9542,
      longitude: 105.5936,
      district: 'H. Diễn Châu',
    ),
    NgheAnLocation(
      name: 'Nghi Lộc – Xã Nghi Phong',
      latitude: 18.7800,
      longitude: 105.6200,
      district: 'H. Nghi Lộc',
    ),
    NgheAnLocation(
      name: 'Đô Lương – Thị trấn Đô Lương',
      latitude: 18.9017,
      longitude: 105.3042,
      district: 'H. Đô Lương',
    ),
    NgheAnLocation(
      name: 'Con Cuông – Thị trấn Con Cuông',
      latitude: 19.0528,
      longitude: 104.8917,
      district: 'H. Con Cuông',
    ),
  ];

  static final Random _rng = Random();

  /// Lấy ngẫu nhiên 1 trong 7 điểm mỗi lần app khởi động
  static NgheAnLocation get randomPoint =>
      points[_rng.nextInt(points.length)];

  /// Lấy điểm gần nhất theo index đã chọn (để dùng nhất quán trong session)
  static NgheAnLocation getByIndex(int index) =>
      points[index.clamp(0, points.length - 1)];
}
