import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../models/sos_model.dart';
import '../utils/app_logger.dart';

/// Dịch vụ P2P Mesh Network (Bluetooth LE / Wifi Direct)
/// Giúp các máy điện thoại tự kết nối thành màng nhện để truyền SOS vào vùng có Internet
class MeshService {
  static final MeshService _instance = MeshService._internal();
  factory MeshService() => _instance;
  MeshService._internal();

  bool _isBroadcasting = false;
  Timer? _meshTimer;

  // Giả lập số lượng điện thoại xung quanh
  final int _nearbyNodesSimulated = Random().nextInt(5) + 1; 

  Future<void> startMeshNetwork(SOSAlertModel localSos) async {
    if (_isBroadcasting) return;
    _isBroadcasting = true;

    appLogger.i('=======================================');
    appLogger.i('📡 KHỞI ĐỘNG P2P MESH NETWORK BLE 📡');
    appLogger.i('=======================================');
    appLogger.i('Đang phát sóng (Advertise) tín hiệu mất mạng qua Bluetooth Low Energy...');

    // Giả lập luồng quét và phát (Scan & Advertise) định kỳ
    _meshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isBroadcasting) {
        timer.cancel();
        return;
      }
      
      final payload = jsonEncode({
        'id': localSos.id.substring(0, 8),
        'lat': localSos.location.latitude.toStringAsFixed(4),
        'lon': localSos.location.longitude.toStringAsFixed(4),
        'ttl': 10, // Chuyển tay tối đa 10 máy
      });

      appLogger.i('⚡ [BLE Broadcast] Vọt gói Payload ${payload.length} bytes: $payload');
      appLogger.i('🔄 $_nearbyNodesSimulated thiết bị lân cận đã nhận gói và đang chuyển tiếp (Hop)!');
    });
  }

  void stopMeshNetwork() {
    _isBroadcasting = false;
    _meshTimer?.cancel();
    appLogger.i('🛑 ĐÃ TẮT MESH NETWORK (Mạng đã có lại)');
  }
}
