// lib/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_alert_model.dart';
import '../models/flood_zone_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../config/theme_config.dart';
import '../widgets/glass_widgets.dart';
import '../utils/cached_tile_provider.dart';
import 'nearby_rescue_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();
  final LatLng _defaultCenter = const LatLng(19.3400, 105.7100);

  List<SOSAlertModel> _alerts = [];
  List<FloodZoneModel> _floodZones = [];
  bool _isLoading = true;
  bool _isLoadingFlood = false;
  bool _showRadar = false;
  bool _showFloodMode = false;

  // Nearby SOS community rescue
  NearbySosData? _nearbySosAlert;
  StreamSubscription<NearbySosData>? _nearbySosSub;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _listenNearbySOS();
  }

  @override
  void dispose() {
    _nearbySosSub?.cancel();
    super.dispose();
  }

  void _listenNearbySOS() {
    _nearbySosSub = SocketService.instance.nearbySosStream.listen((sos) {
      if (!mounted) return;
      setState(() => _nearbySosAlert = sos);
    });
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

  Future<void> _loadFloodZones() async {
    if (_floodZones.isNotEmpty) return; // Cache
    setState(() => _isLoadingFlood = true);
    try {
      final zones = await _apiService.getFloodZones();
      setState(() {
        _floodZones = zones;
        _isLoadingFlood = false;
      });
      // Zoom về trung tâm vùng ngập sau khi tải xong
      if (zones.isNotEmpty) {
        final avgLat = zones.map((z) => z.lat).reduce((a, b) => a + b) / zones.length;
        final avgLon = zones.map((z) => z.lon).reduce((a, b) => a + b) / zones.length;
        _mapController.move(LatLng(avgLat, avgLon), 13.0);
      }
    } catch (e) {
      debugPrint("Lỗi tải bản đồ ngập: $e");
      setState(() => _isLoadingFlood = false);
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
        alert.waterLevel == 'Cao') {
      return ThemeConfig.sosRed;
    }
    if (alert.status == 'warning' || alert.waterLevel == 'Trung bình') {
      return ThemeConfig.warnAmber;
    }
    return const Color(0xFF26A69A);
  }

  Color _getFloodColor(FloodZoneModel zone) {
    if (zone.pFlood >= 0.7) return const Color(0xFFB71C1C); // đỏ đậm
    if (zone.pFlood >= 0.4) return const Color(0xFFE64A19); // cam đỏ
    if (zone.pFlood >= 0.2) return const Color(0xFFF9A825); // vàng
    return const Color(0xFF1B5E20); // xanh lá
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
                const Icon(Icons.map_outlined, color: ThemeConfig.teal, size: 22),
                const SizedBox(width: 10),
                Text(
                  _showFloodMode ? 'Bản đồ Ngập lụt' : 'Bản đồ Cứu hộ',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Spacer(),
                // Toggle mode pill
                GlassPill(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _modeTab(Icons.sos, 'SOS', !_showFloodMode, () {
                        setState(() => _showFloodMode = false);
                      }),
                      _modeTab(Icons.water, 'Ngập', _showFloodMode, () {
                        setState(() => _showFloodMode = true);
                        _loadFloodZones();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Second header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                if (!_showFloodMode) ...[
                  GlassPill(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onTap: () {
                      setState(() => _isLoading = true);
                      _loadAlerts();
                    },
                    child: Row(children: [
                      const Icon(Icons.refresh, size: 14, color: ThemeConfig.tealLight),
                      const SizedBox(width: 4),
                      Text('${_alerts.length} SOS',
                          style: const TextStyle(
                              color: ThemeConfig.tealLight, fontSize: 12)),
                    ]),
                  ),
                ] else ...[
                  GlassPill(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onTap: () {
                      setState(() {
                        _floodZones = [];
                        _isLoadingFlood = true;
                      });
                      _loadFloodZones();
                    },
                    child: Row(children: [
                      const Icon(Icons.refresh, size: 14, color: ThemeConfig.tealLight),
                      const SizedBox(width: 4),
                      Text(
                        _isLoadingFlood
                            ? 'Đang tải...'
                            : '${_floodZones.length} điểm',
                        style: const TextStyle(
                            color: ThemeConfig.tealLight, fontSize: 12)),
                    ]),
                  ),
                ],
              ],
            ),
          ),

          // Map area
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: ThemeConfig.teal))
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _defaultCenter,
                            initialZoom: 10.0,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.floodsos.app',
                              tileProvider: CachedTileProvider(),
                            ),
                            if (_showRadar && ApiService.openWeatherApiKey.isNotEmpty)
                              Opacity(
                                opacity: 0.65,
                                child: TileLayer(
                                  urlTemplate:
                                      'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=${ApiService.openWeatherApiKey}',
                                  userAgentPackageName: 'com.floodsos.app',
                                ),
                              ),
                            // Flood zone – vùng ngập lớn từ AI (useRadiusInMeter=true)
                            if (_showFloodMode && _floodZones.isNotEmpty)
                              CircleLayer(
                                circles: _floodZones.map((zone) {
                                  final color = _getFloodColor(zone);
                                  // Bán kính thay đổi theo mức độ ngập
                                  final radius = zone.pFlood >= 0.7
                                      ? 1200.0
                                      : zone.pFlood >= 0.4
                                          ? 900.0
                                          : zone.pFlood >= 0.2
                                              ? 700.0
                                              : 500.0;
                                  return CircleMarker(
                                    point: LatLng(zone.lat, zone.lon),
                                    radius: radius,
                                    color: color.withValues(alpha: 0.45),
                                    borderColor: color.withValues(alpha: 0.0),
                                    borderStrokeWidth: 0,
                                    useRadiusInMeter: true,
                                  );
                                }).toList(),
                              ),
                            // SOS Markers
                            if (!_showFloodMode)
                              MarkerLayer(markers: _buildMarkers()),
                          ],
                        ),
                      ),

                      // Loading flood overlay
                      if (_showFloodMode && _isLoadingFlood)
                        Container(
                          color: Colors.black45,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: ThemeConfig.teal),
                                SizedBox(height: 12),
                                Text('Đang tải bản đồ ngập...',
                                    style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ),

                      // SOS Empty state
                      if (!_showFloodMode && _alerts.isEmpty)
                        const Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: GlassCard(
                            borderRadius: 14,
                            padding: EdgeInsets.all(14),
                            child: Row(children: [
                              Icon(Icons.info_outline,
                                  color: ThemeConfig.tealLight),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Hiện chưa có yêu cầu cứu hộ nào',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ]),
                          ),
                        ),

                      // Flood offline notice
                      if (_showFloodMode && !_isLoadingFlood && _floodZones.isEmpty)
                        const Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: GlassCard(
                            borderRadius: 14,
                            padding: EdgeInsets.all(14),
                            child: Row(children: [
                              Icon(Icons.cloud_off, color: Colors.orangeAccent),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Dịch vụ AI ngập lụt chưa khởi động.\nHãy chạy priority_api.py để kích hoạt.',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ),
                            ]),
                          ),
                        ),

                      // ── Nearby SOS community rescue banner ─────────────
                      if (_nearbySosAlert != null)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: _NearbySosBanner(
                            sos: _nearbySosAlert!,
                            myName: 'Người dùng',
                            myPhone: '',
                            onDismiss: () =>
                                setState(() => _nearbySosAlert = null),
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
                            children: _showFloodMode
                                ? [
                                    const Text('Mức ngập',
                                        style: TextStyle(
                                            color: ThemeConfig.tealLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                    const SizedBox(height: 6),
                                    _legendItem(const Color(0xFFB71C1C), 'Nguy cấp (≥70%)'),
                                    _legendItem(const Color(0xFFE64A19), 'Cao (40-70%)'),
                                    _legendItem(const Color(0xFFF9A825), 'Trung bình (20%)'),
                                    _legendItem(const Color(0xFF1B5E20), 'Thấp (<20%)'),
                                  ]
                                : [
                                    const Text('Chú giải',
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
                              if (_alerts.isNotEmpty && !_showFloodMode) {
                                _fitBoundsToAlerts();
                              } else {
                                _mapController.move(_defaultCenter, 10.0);
                              }
                            }),
                            const SizedBox(height: 8),
                            _mapFab(_showRadar ? Icons.cloud_off : Icons.cloudy_snowing, () {
                              setState(() => _showRadar = !_showRadar);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_showRadar
                                      ? 'Đã bật lớp mây & mưa'
                                      : 'Đã tắt radar mưa'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: ThemeConfig.teal,
                                ),
                              );
                            }, isActive: _showRadar),
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

  Widget _modeTab(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active
              ? ThemeConfig.teal.withValues(alpha: 0.3)
              : Colors.transparent,
          border: active
              ? Border.all(color: ThemeConfig.teal, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? ThemeConfig.teal : Colors.white54),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? ThemeConfig.teal : Colors.white54,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _mapFab(IconData icon, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive ? ThemeConfig.oceanGradient : ThemeConfig.tealGradient,
          border: isActive ? Border.all(color: Colors.white, width: 1.5) : null,
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
                          color: _getAlertColor(alert).withValues(alpha: 0.5)),
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
                          style: const TextStyle(
                              color: ThemeConfig.tealLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: ThemeConfig.glassBorder),
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
                      const Text('💬 Lời nhắn:',
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
                      onPressed: () async {
                        Navigator.pop(context);
                        final url = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${alert.latitude},${alert.longitude}&travelmode=driving');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.navigation_outlined, size: 16),
                      label: const Text('Chỉ đường'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeConfig.teal,
                        side: const BorderSide(color: ThemeConfig.teal),
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
                          final url = Uri(scheme: 'tel', path: alert.phone);
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
                  const TextStyle(color: ThemeConfig.tealLight, fontSize: 13)),
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

// ── Banner cảnh báo hàng xóm cần giúp ─────────────────────────────────────────
class _NearbySosBanner extends StatelessWidget {
  final NearbySosData sos;
  final String myName;
  final String myPhone;
  final VoidCallback onDismiss;

  const _NearbySosBanner({
    required this.sos,
    required this.myName,
    required this.myPhone,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NearbyRescueScreen(
                sos: sos,
                myName: myName,
                myPhone: myPhone,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.handshake, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🆘 Hàng xóm cần giúp đỡ!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    Text(
                      '${sos.name.isEmpty ? "Người dùng" : sos.name} • ${sos.distanceM}m',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Xem',
                      style: TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
