// lib/screens/sos_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../models/sos_model.dart';
import '../services/firebase_service.dart';

class SOSTrackingScreen extends StatelessWidget {
  final String sosId;
  final bool isOffline;

  const SOSTrackingScreen({
    Key? key,
    required this.sosId,
    this.isOffline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Desktop hoặc Offline mode
    if (isOffline || !FirebaseService.isSupported) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            FirebaseService.isSupported
                ? "Trạng thái SOS (Offline)"
                : "SOS (Desktop Mode)",
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                FirebaseService.isSupported
                    ? "Đang chờ kết nối mạng để đồng bộ..."
                    : "🖥️ Running on Desktop - Firebase disabled",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text("SOS ID: ${sosId.substring(0, 8)}",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Mobile/Web: Real-time tracking
    final stream = FirebaseService.sosStream(sosId);
    if (stream == null) {
      return Scaffold(
        body: Center(child: Text("Unable to load SOS data")),
      );
    }

    return StreamBuilder<dynamic>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Không tìm thấy SOS")),
          );
        }

        final sos = SOSAlertModel.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(title: Text("SOS #${sosId.substring(0, 5)}")),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header Map (Placeholder)
                if (sos.status == SOSStatus.EN_ROUTE ||
                    sos.status == SOSStatus.DISPATCHING)
                  Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text("🗺️ Live Map Tracking Here"),
                    ),
                  ),

                const SizedBox(height: 20),
                const Text(
                  "Tiến trình xử lý",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Timeline
                Expanded(
                  child: ListView.builder(
                    itemCount: sos.history.length,
                    itemBuilder: (context, index) {
                      final historyItem = sos.history[index];
                      return _buildTimelineTile(
                        historyItem,
                        index == sos.history.length - 1,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineTile(StatusHistory history, bool isLast) {
    return TimelineTile(
      isFirst: false,
      isLast: isLast,
      beforeLineStyle: const LineStyle(color: Colors.blueAccent),
      indicatorStyle: IndicatorStyle(
        width: 30,
        color: Colors.blueAccent,
        iconStyle: IconStyle(
          iconData: _getStatusIcon(history.status),
          color: Colors.white,
        ),
      ),
      endChild: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 5,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getStatusText(history.status),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('HH:mm dd/MM').format(history.timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (history.note != null)
              Text(
                history.note!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(SOSStatus status) {
    switch (status) {
      case SOSStatus.SENT:
        return Icons.send;
      case SOSStatus.RECEIVED:
        return Icons.check_circle_outline;
      case SOSStatus.DISPATCHING:
        return Icons.headset_mic;
      case SOSStatus.EN_ROUTE:
        return Icons.directions_boat;
      case SOSStatus.COMPLETED:
        return Icons.check_circle;
      case SOSStatus.CANCELLED:
        return Icons.cancel;
    }
  }

  String _getStatusText(SOSStatus status) {
    switch (status) {
      case SOSStatus.SENT:
        return "Đã gửi yêu cầu";
      case SOSStatus.RECEIVED:
        return "Hệ thống đã nhận";
      case SOSStatus.DISPATCHING:
        return "Đang điều phối";
      case SOSStatus.EN_ROUTE:
        return "Đội cứu hộ đang đến";
      case SOSStatus.COMPLETED:
        return "Hoàn thành";
      case SOSStatus.CANCELLED:
        return "Đã hủy";
    }
  }
}
