import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/api_service.dart'; // Lấy baseUrl từ đây cho đồng bộ

class SocketService {
  // Singleton: Đảm bảo chỉ có 1 kết nối duy nhất trong toàn App
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;

  // Getter để các Provider khác có thể dùng socket này lắng nghe sự kiện
  io.Socket? get socket => _socket;

  // Hàm khởi tạo kết nối
  void connect() {
    // Nếu đã kết nối rồi thì thôi
    if (_socket != null && _socket!.connected) return;

    // Lấy URL từ ApiService (đã sửa thành cổng 3001)
    // Lưu ý: Socket.io cần URL dạng 'http://IP:PORT', không cần /api/...
    final String socketUrl = ApiService.baseUrl;

    debugPrint("🔌 SocketService: Đang kết nối tới $socketUrl");

    try {
      _socket = io.io(
          socketUrl,
          io.OptionBuilder()
              .setTransports(['websocket']) // Bắt buộc dùng WebSocket cho nhanh
              .disableAutoConnect() // Tắt tự động để kiểm soát thủ công
              .enableForceNew()
              .build());

      _socket!.connect();

      // --- LOG TRẠNG THÁI ---
      _socket!.onConnect((_) {
        debugPrint('✅ Socket Connected! ID: ${_socket!.id}');
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ Socket Disconnected');
      });

      _socket!.onConnectError((err) {
        debugPrint('⚠️ Socket Error: $err');
      });
    } catch (e) {
      debugPrint("💀 Lỗi khởi tạo Socket: $e");
    }
  }

  void disconnect() {
    _socket?.disconnect();
  }
}
