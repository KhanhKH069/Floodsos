import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tracking_service.dart';
import '../providers/auth_provider.dart';

class TrackingBroadcasterWidget extends StatefulWidget {
  const TrackingBroadcasterWidget({super.key});

  @override
  State<TrackingBroadcasterWidget> createState() =>
      _TrackingBroadcasterWidgetState();
}

class _TrackingBroadcasterWidgetState extends State<TrackingBroadcasterWidget> {
  final TrackingService _trackingService = TrackingService();
  bool _isBroadcasting = false;
  TrackingRole _selectedRole = TrackingRole.evacuee;

  @override
  void initState() {
    super.initState();
    _isBroadcasting = _trackingService.isBroadcasting;
    _selectedRole = _trackingService.currentRole;
    
    // Khởi tạo TrackingService với tên của người dùng (nếu chưa gọi)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _trackingService.init(auth.user?.name ?? 'Người dùng ẩn danh');
    });
  }

  void _toggleTracking(bool value) async {
    if (value) {
      await _trackingService.startBroadcasting(_selectedRole);
    } else {
      _trackingService.stopBroadcasting();
    }
    setState(() {
      _isBroadcasting = _trackingService.isBroadcasting;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isBroadcasting
            ? Colors.teal.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isBroadcasting
              ? Colors.teal.withValues(alpha: 0.5)
              : Colors.blueGrey.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isBroadcasting ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: _isBroadcasting ? Colors.teal : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chia sẻ Hành trình Vị trí',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _isBroadcasting ? Colors.teal : Colors.black87,
                      ),
                    ),
                    Text(
                      _isBroadcasting
                          ? 'Đang phát sóng vị trí thời gian thực'
                          : 'Bật để cung cấp vị trí cho đội cứu hộ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isBroadcasting,
                onChanged: _toggleTracking,
                activeThumbColor: Colors.teal,
              ),
            ],
          ),
          if (!_isBroadcasting) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Vai trò của bạn: ',
                    style: TextStyle(fontSize: 13, color: Colors.black87)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Gặp nạn / Di tản', style: TextStyle(fontSize: 12)),
                  selected: _selectedRole == TrackingRole.evacuee,
                  onSelected: (val) {
                    if (val) setState(() => _selectedRole = TrackingRole.evacuee);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Cứu hộ', style: TextStyle(fontSize: 12)),
                  selected: _selectedRole == TrackingRole.rescuer,
                  onSelected: (val) {
                    if (val) setState(() => _selectedRole = TrackingRole.rescuer);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
