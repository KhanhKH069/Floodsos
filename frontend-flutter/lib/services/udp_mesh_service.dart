import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../utils/app_logger.dart';

class UdpMeshService {
  static final UdpMeshService _instance = UdpMeshService._internal();
  factory UdpMeshService() => _instance;
  UdpMeshService._internal();

  RawDatagramSocket? _socket;
  final String _multicastAddress = '224.0.2.200';
  final int _port = 8888;
  
  // Stream controller để UI (AdminTrackingScreen) dễ dàng listen
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onTrackingDataReceived => _messageController.stream;

  bool _isListening = false;

  /// Khởi tạo và Bật tai nghe "Radar" (chỉ chạy ở phe nhận mạng hoặc cần phát)
  Future<void> start() async {
    if (_isListening) return;

    try {
      // Bind socket (Lắng nghe bất kỳ IP nào trên port 8888)
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
      _socket!.readEventsEnabled = true;
      _socket!.multicastHops = 1; // Chỉ gửi trong 1 mạng nội bộ (Wi-Fi/Hotspot)
      
      // Tham gia vào nhóm Multicast để vớt các gói phát đi vào định tuyến cục bộ
      final multicastGroup = InternetAddress(_multicastAddress);
      
      try {
        _socket!.joinMulticast(multicastGroup);
      } catch (e) {
        appLogger.w("⚠️ Thiết bị không hỗ trợ Multicast full, fallback sang Broadcast: $e");
        _socket!.broadcastEnabled = true; // Fallback Broadcast
      }

      appLogger.i("📡 [UDP Mesh] Đã khởi chạy Radar trên port $_port!");
      _isListening = true;

      // Lắng nghe tín hiệu dội vào Radar
      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final Datagram? datagram = _socket!.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });
    } catch (e) {
      appLogger.e("❌ [UDP Mesh] Lỗi kết nối Radar: $e");
    }
  }

  void _handleIncomingPacket(Datagram datagram) {
    try {
      final String payload = utf8.decode(datagram.data);
      final Map<String, dynamic> data = jsonDecode(payload);

      // Đóng dấu gói tin này là từ Local Network
      data['networkType'] = 'mesh';
      // Trích xuất Sender IP nếu cần làm thống kê
      data['senderIp'] = datagram.address.address;

      _messageController.add(data);
      // appLogger.i("⚡ [UDP Nhận] Tọa độ của ${data['name']} (IP: ${datagram.address.address})");
    } catch (e) {
      // Bỏ qua gói tin không đúng chuẩn
      appLogger.e("⚠️ [UDP Mesh] Gói tin rác: $e");
    }
  }

  /// Ném tín hiệu vào không gian (Phát sóng)
  void broadcastTracking(Map<String, dynamic> locationData) {
    if (_socket == null) return;
    try {
      final String payload = jsonEncode(locationData);
      final List<int> bytes = utf8.encode(payload);

      // Gửi vào kênh Multicast
      _socket!.send(bytes, InternetAddress(_multicastAddress), _port);

      // Khả năng dự phòng: Gửi xả vào 255.255.255.255 để các máy đời cũ bắt được
      if (_socket!.broadcastEnabled) {
         _socket!.send(bytes, InternetAddress('255.255.255.255'), _port);
      }
      
      appLogger.i("⚡ [UDP Phát] Vọt gói tọa độ Mesh (Kích thước: ${bytes.length} bytes)");
    } catch (e) {
      appLogger.w("⚠️ [UDP Phát] Không thể ném gói tin: $e");
    }
  }

  void stop() {
    _socket?.close();
    _socket = null;
    _isListening = false;
    appLogger.i("🛑 [UDP Mesh] Đã tắt Radar nội bộ.");
  }
}
