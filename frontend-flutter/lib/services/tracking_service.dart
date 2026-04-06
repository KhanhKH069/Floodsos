import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/socket_service.dart';
import '../services/tracking_offline_buffer.dart';
import '../services/api_service.dart';
import '../services/udp_mesh_service.dart';
import '../utils/app_logger.dart';

enum TrackingRole { evacuee, rescuer }

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final Battery _battery = Battery();
  final TrackingOfflineBuffer _buffer = TrackingOfflineBuffer();

  StreamSubscription<Position>? _positionStream;
  bool _isBroadcasting = false;
  TrackingRole _currentRole = TrackingRole.evacuee;
  String _deviceId = '';
  String _userName = 'Khách';

  bool get isBroadcasting => _isBroadcasting;
  TrackingRole get currentRole => _currentRole;

  Future<void> init(String userName) async {
    _userName = userName;
    _deviceId = await _getDeviceId();
  }

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final webBrowserInfo = await deviceInfo.webBrowserInfo;
      return webBrowserInfo.userAgent ?? 'web_browser_${DateTime.now().millisecondsSinceEpoch}';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios_device';
    }
    return 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> startBroadcasting(TrackingRole role) async {
    if (_isBroadcasting) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      appLogger.w('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _currentRole = role;
    _isBroadcasting = true;
    appLogger.i("🚀 Bắt đầu phát sóng GPS (${role.name})...");

    // Mở kết nối Socket (Internet)
    SocketService().connect();

    // Mở kết nối Radar Lưới (Local Offline Mesh)
    await UdpMeshService().start();

    // Lấy stream liên tục mỗi 5s hoặc khi đi 5 mét
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Cập nhật khi đi 5 mét
      ),
    ).listen((Position position) {
      _handleNewPosition(position);
    });

    // Thử đồng bộ dữ liệu cũ ngay nếu có mạng
    _syncOfflineData();
  }

  void stopBroadcasting() {
    _isBroadcasting = false;
    _positionStream?.cancel();
    _positionStream = null;
    
    // Tắt Radar
    UdpMeshService().stop();
    appLogger.i("🛑 Đã dừng phát sóng GPS (Cả Internet và Mesh).");
  }

  Future<void> _handleNewPosition(Position position) async {
    final batteryLevel = await _battery.batteryLevel;
    
    final data = {
      'deviceId': _deviceId,
      'name': _userName,
      'role': _currentRole.name,
      'lat': position.latitude,
      'lon': position.longitude,
      'speed': position.speed, // Tốc độ m/s
      'battery': batteryLevel,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final socket = SocketService().socket;

    if (socket != null && socket.connected) {
      // Có mạng => Emit trực tiếp lên Server Node.js
      socket.emit('location_update', data);
      appLogger.i("📡 Bắn GPS qua Socket (Internet): lat ${data['lat']}, lon ${data['lon']}");
    } else {
      // Mất mạng => Lưu vào SQLite buffer
      appLogger.w("⚠️ Mất mạng, đã lưu vị trí vào buffer SQLite để chờ sync...");
      await _buffer.saveLocationObject(data);
    }

    // 🌟 LUÔN PHÁT UDP MESH (bất chấp Online/Offline)
    // Để Admin đứng gần trong cùng mạng Wi-Fi Hotspot thấy ngay.
    UdpMeshService().broadcastTracking(data);
  }

  /// Gọi khi kết nối Socket thành công hoặc có nút Sync tay
  Future<void> _syncOfflineData() async {
    final socket = SocketService().socket;
    if (socket == null || !socket.connected) return;

    final pending = await _buffer.getPendingLocations();
    if (pending.isEmpty) return;

    appLogger.i("🔄 Đang đồng bộ ${pending.length} tọa độ bị kẹt...");
    
    try {
      final dio = Dio();
      final url = '${ApiService.baseUrl}/api/sos/tracking/sync';
      
      final payload = {
        'deviceId': _deviceId,
        'role': _currentRole.name,
        'trackingData': pending, // Mảng các obj
      };

      final response = await dio.post(url, data: payload);

      if (response.statusCode == 200) {
        appLogger.i("✅ Đồng bộ thành công ${pending.length} tọa độ!");
        await _buffer.clearBuffer();
      }
    } catch (e) {
      appLogger.e("❌ Đồng bộ offline thất bại: $e");
    }
  }
}
