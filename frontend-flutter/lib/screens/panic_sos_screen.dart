// lib/screens/panic_sos_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sos_model.dart';
import '../services/offline_service.dart';
import '../services/firebase_service.dart';
import 'sos_tracking_screen.dart';

class PanicSOSScreen extends StatefulWidget {
  const PanicSOSScreen({Key? key}) : super(key: key);

  @override
  _PanicSOSScreenState createState() => _PanicSOSScreenState();
}

class _PanicSOSScreenState extends State<PanicSOSScreen> {
  bool _isSending = false;
  final OfflineService _offlineService = OfflineService();

  Future<void> _handleEmergencySOS() async {
    setState(() => _isSending = true);

    // Mock data (Thay bằng LocationService thật)
    final mockLocation = FirebaseService.createGeoPoint(21.0285, 105.8542);
    final String newId = const Uuid().v4();

    final newSOS = SOSAlertModel(
      id: newId,
      userId: 'current_user_id', // Lấy từ Auth
      location: mockLocation,
      waterLevel: 'Khẩn cấp',
      peopleCount: 1,
      createdAt: DateTime.now(),
      status: SOSStatus.SENT,
      history: [
        StatusHistory(
          status: SOSStatus.SENT,
          timestamp: DateTime.now(),
          note: 'Panic Button',
        )
      ],
    );

    try {
      // 1. Thử gửi lên Firestore (nếu có)
      if (FirebaseService.isSupported) {
        await FirebaseService.saveSOS(newId, newSOS.toMap())
            .timeout(const Duration(seconds: 3));
      } else {
        // Desktop: Chỉ lưu local
        throw Exception('Desktop mode - no Firebase');
      }

      // 2. Thành công -> Chuyển màn hình tracking
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SOSTrackingScreen(sosId: newId),
          ),
        );
      }
    } catch (e) {
      // 3. Thất bại (Offline/Desktop) -> Lưu Local
      await _offlineService.savePendingSOS(newSOS);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirebaseService.isSupported
                  ? 'Đang offline. SOS đã lưu và sẽ gửi khi có mạng!'
                  : '🖥️ Desktop mode: SOS saved locally',
            ),
          ),
        );

        // Vẫn chuyển sang tracking (offline view)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SOSTrackingScreen(sosId: newId, isOffline: true),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: Center(
        child: GestureDetector(
          onLongPress: _handleEmergencySOS, // Giữ để gửi
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSending ? 280 : 300,
            height: _isSending ? 280 : 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sos, size: 100, color: Colors.red.shade700),
                const SizedBox(height: 20),
                Text(
                  _isSending ? 'ĐANG GỬI...' : 'GIỮ 2 GIÂY',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
