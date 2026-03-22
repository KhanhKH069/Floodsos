// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_alert_model.dart';
import '../services/api_service.dart';
import '../config/theme_config.dart';
import '../widgets/glass_widgets.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();
  final LatLng _defaultCenter = const LatLng(19.3400, 105.7100);

  List<SOSAlertModel> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _apiService.getSOSAlerts();
      setState(() {
        _alerts = alerts
            .where((a) => a.latitude != 0.0 && a.longitude != 0.0)
            .toList();
        _isLoading = false;
      });
      if (_alerts.isNotEmpty) _fitBoundsToAlerts();
    } catch (e) {
      debugPrint("Lỗi tải bản đồ: $e");
      setState(() => _isLoading = false);
    }
  }

  void _fitBoundsToAlerts() {
    if (_alerts.isEmpty) return;
    double minLat = _alerts.first.latitude;
    double maxLat = _alerts.first.latitude;
    double minLon = _alerts.first.longitude;
    double maxLon = _alerts.first.longitude;
    for (var a in _alerts) {
      if (a.latitude < minLat) minLat = a.latitude;
      if (a.latitude > maxLat) maxLat = a.latitude;
      if (a.longitude < minLon) minLon = a.longitude;
      if (a.longitude > maxLon) maxLon = a.longitude;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Color _getAlertColor(SOSAlertModel alert) {
    if (alert.status == 'critical' ||
        alert.waterLevel == 'Khẩn cấp' ||
        alert.waterLevel == 'Cao') return ThemeConfig.sosRed;
    if (alert.status == 'warning' || alert.waterLevel == 'Trung bình')
      return ThemeConfig.warnAmber;
    return const Color(0xFF26A69A);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ThemeConfig.oceanGradient),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.map_outlined, color: ThemeConfig.teal, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Bản đồ Cứu hộ',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Spacer(),
                GlassPill(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  onTap: () {
                    setState(() => _isLoading = true);
                    _loadAlerts();
                  },
                  child: Row(children: [
                    Icon(Icons.refresh, size: 14, color: ThemeConfig.tealLight),
                    const SizedBox(width: 4),
                    Text('${_alerts.length} SOS',
                        style: TextStyle(
                            color: ThemeConfig.tealLight, fontSize: 12)),
                  ]),
                ),
              ],
            ),
          ),

          // Map area
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: ThemeConfig.teal))
                : Stack(
                    children: [
                      // Map
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _defaultCenter,
                            initialZoom: 13.0,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.floodsos.app',
                            ),
                            MarkerLayer(markers: _buildMarkers()),
                          ],
                        ),
                      ),

                      // Empty state
                      if (_alerts.isEmpty)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: GlassCard(
                            borderRadius: 14,
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Icon(Icons.info_outline,
                                  color: ThemeConfig.tealLight),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Hiện chưa có yêu cầu cứu hộ nào',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ]),
                          ),
                        ),

                      // Legend
                      Positioned(
                        left: 12,
                        bottom: 16,
                        child: GlassCard(
                          borderRadius: 14,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Chú giải',
                                  style: TextStyle(
                                      color: ThemeConfig.tealLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              const SizedBox(height: 6),
                              _legendItem(ThemeConfig.sosRed, 'Nguy cấp'),
                              _legendItem(ThemeConfig.warnAmber, 'Cảnh báo'),
                              _legendItem(
                                  const Color(0xFF26A69A), 'An toàn'),
                            ],
                          ),
                        ),
                      ),

                      // FABs
                      Positioned(
                        right: 12,
                        bottom: 16,
                        child: Column(
                          children: [
                            _mapFab(Icons.center_focus_strong, () {
                              if (_alerts.isNotEmpty) {
                                _fitBoundsToAlerts();
                              } else {
                                _mapController.move(_defaultCenter, 13.0);
                              }
                            }),
                            const SizedBox(height: 8),
                            _mapFab(Icons.add, () {
                              final z = _mapController.camera.zoom;
                              _mapController.move(
                                  _mapController.camera.center, z + 1);
                            }),
                            const SizedBox(height: 8),
                            _mapFab(Icons.remove, () {
                              final z = _mapController.camera.zoom;
                              _mapController.move(
                                  _mapController.camera.center, z - 1);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _mapFab(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: ThemeConfig.tealGradient,
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.teal.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _alerts.map((alert) {
      final alertColor = _getAlertColor(alert);
      return Marker(
        point: LatLng(alert.latitude, alert.longitude),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _showAlertDetails(alert),
          child: Container(
            decoration: BoxDecoration(
              color: alertColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: alertColor.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.sos, color: Colors.white, size: 24),
          ),
        ),
      );
    }).toList();
  }

  void _showAlertDetails(SOSAlertModel alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(12),
        child: GlassCard(
          borderRadius: 24,
          borderColor: _getAlertColor(alert).withValues(alpha: 0.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: ThemeConfig.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getAlertColor(alert).withValues(alpha: 0.2),
                      border: Border.all(
                          color:
                              _getAlertColor(alert).withValues(alpha: 0.5)),
                    ),
                    child: Icon(Icons.sos,
                        color: _getAlertColor(alert), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOS từ ${alert.name.isEmpty ? "Người dùng" : alert.name}',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        Text(
                          alert.status == 'critical'
                              ? '🔴 Đang nguy cấp'
                              : '🟠 Cần hỗ trợ',
                          style: TextStyle(
                              color: ThemeConfig.tealLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                  height: 24,
                  color: ThemeConfig.glassBorder),
              _infoRow('📍', 'Vị trí',
                  '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}'),
              _infoRow('📞', 'SĐT',
                  alert.phone.isEmpty ? 'Không có' : alert.phone),
              _infoRow('👥', 'Số người', '${alert.peopleCount ?? '?'} người'),
              _infoRow('🌊', 'Mức nước', alert.waterLevel ?? 'Chưa rõ'),
              _infoRow('🕐', 'Thời gian', _formatTime(alert.createdAt)),

              if (alert.message != null && alert.message!.isNotEmpty) ...[
                const SizedBox(height: 10),
                GlassPill(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💬 Lời nhắn:',
                          style: TextStyle(
                              color: ThemeConfig.tealLight, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(alert.message!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Chỉ đường'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeConfig.teal,
                        side: BorderSide(color: ThemeConfig.teal),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (alert.phone.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final url =
                              Uri(scheme: 'tel', path: alert.phone);
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        },
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Gọi điện'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26A69A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text('$label: ',
              style:
                  TextStyle(color: ThemeConfig.tealLight, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "Vừa xong";
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    return "${time.day}/${time.month} lúc ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
