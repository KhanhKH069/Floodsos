import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart'; // Lấy baseUrl từ đây cho đồng bộ

class SocketService {
  // Singleton: Đảm bảo chỉ có 1 kết nối duy nhất trong toàn App
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // Getter để các Provider khác có thể dùng socket này lắng nghe sự kiện
  IO.Socket? get socket => _socket;

  // Hàm khởi tạo kết nối
  void connect() {
    // Nếu đã kết nối rồi thì thôi
    if (_socket != null && _socket!.connected) return;

    // Lấy URL từ ApiService (đã sửa thành cổng 3001)
    // Lưu ý: Socket.io cần URL dạng 'http://IP:PORT', không cần /api/...
    final String socketUrl = ApiService.baseUrl;

    print("🔌 SocketService: Đang kết nối tới $socketUrl");

    try {
      _socket = IO.io(
          socketUrl,
          IO.OptionBuilder()
              .setTransports(['websocket']) // Bắt buộc dùng WebSocket cho nhanh
              .disableAutoConnect() // Tắt tự động để kiểm soát thủ công
              .enableForceNew()
              .build());

      _socket!.connect();

      // --- LOG TRẠNG THÁI ---
      _socket!.onConnect((_) {
        print('✅ Socket Connected! ID: ${_socket!.id}');
      });

      _socket!.onDisconnect((_) {
        print('❌ Socket Disconnected');
      });

      _socket!.onConnectError((err) {
        print('⚠️ Socket Error: $err');
      });
    } catch (e) {
      print("💀 Lỗi khởi tạo Socket: $e");
    }
  }

  void disconnect() {
    _socket?.disconnect();
  }
}
