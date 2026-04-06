// lib/services/socket_service.dart
/// SocketService — singleton quản lý kết nối Socket.IO với backend.
/// Cung cấp stream để lắng nghe nearby_sos và volunteer_update.
library;


import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;
import 'api_service.dart';

class NearbySosData {
  final String sosId;
  final String name;
  final String phone;
  final double lat;
  final double lon;
  final String waterLevel;
  final dynamic peopleCount;
  final String message;
  final String mobilityStatus;
  final int distanceM;

  const NearbySosData({
    required this.sosId,
    required this.name,
    required this.phone,
    required this.lat,
    required this.lon,
    required this.waterLevel,
    required this.peopleCount,
    required this.message,
    required this.mobilityStatus,
    required this.distanceM,
  });

  factory NearbySosData.fromMap(Map<String, dynamic> m) => NearbySosData(
        sosId: m['sosId']?.toString() ?? '',
        name: m['name']?.toString() ?? 'Người dùng',
        phone: m['phone']?.toString() ?? '',
        lat: (m['lat'] as num? ?? 0).toDouble(),
        lon: (m['lon'] as num? ?? 0).toDouble(),
        waterLevel: m['waterLevel']?.toString() ?? '',
        peopleCount: m['peopleCount'] ?? 1,
        message: m['message']?.toString() ?? '',
        mobilityStatus: m['mobilityStatus']?.toString() ?? 'can_walk',
        distanceM: (m['distanceM'] as num? ?? 0).toInt(),
      );
}

class VolunteerUpdate {
  final String sosId;
  final String status; // accepted / arrived / completed
  final String? volunteerName;
  final String? volunteerPhone;

  const VolunteerUpdate({
    required this.sosId,
    required this.status,
    this.volunteerName,
    this.volunteerPhone,
  });

  factory VolunteerUpdate.fromMap(Map<String, dynamic> m) => VolunteerUpdate(
        sosId: m['sosId']?.toString() ?? '',
        status: m['status']?.toString() ?? '',
        volunteerName: m['volunteerName']?.toString(),
        volunteerPhone: m['volunteerPhone']?.toString(),
      );
}

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  // ── Backward-compatible factory constructor ────────────────────────────────
  // Legacy code uses SocketService() — route to singleton
  factory SocketService() => instance;

  sio.Socket? _socket;
  bool _connected = false;

  final _nearbySosCtrl = StreamController<NearbySosData>.broadcast();
  final _volunteerCtrl = StreamController<VolunteerUpdate>.broadcast();
  final _sosResolvedCtrl = StreamController<String>.broadcast();

  Stream<NearbySosData> get nearbySosStream => _nearbySosCtrl.stream;
  Stream<VolunteerUpdate> get volunteerStream => _volunteerCtrl.stream;
  Stream<String> get sosResolvedStream => _sosResolvedCtrl.stream;

  bool get isConnected => _connected;

  /// Backward-compat: legacy code accesses SocketService().socket directly
  sio.Socket? get socket => _socket;

  void connect() {
    if (_socket != null) return;
    final url = ApiService.baseUrl;
    debugPrint('[Socket] Connecting to $url');

    _socket = sio.io(url, sio.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(10)
        .build());

    _socket!.onConnect((_) {
      _connected = true;
      debugPrint('[Socket] ✅ Connected');
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      debugPrint('[Socket] ❌ Disconnected');
    });

    _socket!.on('nearby_sos', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        _nearbySosCtrl.add(NearbySosData.fromMap(map));
        debugPrint('[Socket] 🆘 nearby_sos: ${map['name']} ${map['distanceM']}m');
      } catch (e) {
        debugPrint('[Socket] nearby_sos parse error: $e');
      }
    });

    _socket!.on('volunteer_update', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        _volunteerCtrl.add(VolunteerUpdate.fromMap(map));
      } catch (e) {
        debugPrint('[Socket] volunteer_update parse error: $e');
      }
    });

    _socket!.on('sos_resolved', (data) {
      try {
        final map = Map<String, dynamic>.from(data as Map);
        _sosResolvedCtrl.add(map['sosId']?.toString() ?? '');
      } catch (e) {
        debugPrint('[Socket] sos_resolved parse error: $e');
      }
    });
  }

  void sendLocationUpdate({
    required String deviceId,
    required String name,
    required double lat,
    required double lon,
  }) {
    if (_socket == null || !_connected) return;
    _socket!.emit('location_update', {
      'deviceId': deviceId,
      'name': name,
      'role': 'user',
      'lat': lat,
      'lon': lon,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void emitVolunteerAccepted({
    required String sosId,
    required String volunteerName,
    required String volunteerPhone,
  }) {
    _socket?.emit('volunteer_accepted', {
      'sosId': sosId,
      'volunteerName': volunteerName,
      'volunteerPhone': volunteerPhone,
    });
  }

  void emitVolunteerArrived(String sosId) {
    _socket?.emit('volunteer_arrived', {'sosId': sosId});
  }

  void emitVolunteerCompleted(String sosId) {
    _socket?.emit('volunteer_completed', {'sosId': sosId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
  }
}
