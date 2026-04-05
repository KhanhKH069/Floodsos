// lib/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/sos_alert_model.dart';
import '../models/flood_report_model.dart';
import '../models/drone_model.dart';
import '../models/shelter_model.dart';
import '../services/api_service.dart';
import '../services/in_app_notification_service.dart';
import '../config/theme_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  final bool isSurvivalMode;
  const MapScreen({super.key, this.isSurvivalMode = false});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();

  // Tọa độ trung tâm mặc định (Nghệ An - Hà Tĩnh)
  final LatLng _defaultCenter = const LatLng(18.6733, 105.6924);

  List<SOSAlertModel> get _alerts => context.read<MapProvider>().alerts;
  List<FloodReportModel> get _reports => context.read<MapProvider>().reports;
  List<FloodReportModel> get _predictiveReports => context.read<MapProvider>().predictiveReports;
  List<DroneModel> get _drones => context.read<MapProvider>().drones;
  List<ShelterModel> get _shelters => context.read<MapProvider>().shelters;
  bool get _isLoading => context.watch<MapProvider>().isLoading;

  bool _showPrediction = false;
  bool _showDrones = true; // ← Toggle hiển thị drone
  List<LatLng> _safeRoute = []; // Đường đi an toàn
  late io.Socket _socket;

  // ── DRONE ANIMATION ──────────────────────────
  late AnimationController _droneHoverController;
  late Animation<double> _droneHoverAnim;
  Timer? _droneRefreshTimer;
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Khởi tạo animation hover cho drone
    _droneHoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _droneHoverAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _droneHoverController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MapProvider>().loadAllData();
      if (mounted && _alerts.isNotEmpty) _fitBoundsToAlerts();
    });
    
    _connectSocket();

    // Refresh drone mỗi 5 giây
    _droneRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _loadDrones());
  }

  void _connectSocket() {
    _socket = io.io(
        'http://192.168.1.14:3002',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());
    _socket.connect();

    // SOS mới → reload + show notification
    _socket.on('sos_updated', (_) {
      _loadAlerts();
      if (mounted) {
        InAppNotificationService.showSOS(
          context,
          detail: 'Bản đồ đang được cập nhật với SOS mới nhất.',
        );
      }
    });

    // Report mới → reload + show notification
    _socket.on('report_updated', (_) {
      _loadAlerts();
      if (mounted) {
        InAppNotificationService.showFloodReport(
          context,
          detail: 'Điểm ngập mới vừa được thêm vào bản đồ cộng đồng.',
        );
      }
    });

    // Drone cập nhật → reload drone + show notification
    _socket.on('drones_updated', (_) {
      _loadDrones();
      if (mounted) {
        InAppNotificationService.showDroneUpdate(
          context,
          detail: 'Vị trí drone đã được cập nhật trên bản đồ.',
        );
      }
    });
  }

  @override
  void dispose() {
    _droneHoverController.dispose();
    _droneRefreshTimer?.cancel();
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  // 🔴 Tải dữ liệu SOS thật từ API
  Future<void> _loadAlerts() async {
    if (!mounted) return;
    await context.read<MapProvider>().reloadAlertsAndReports();
    if (mounted && _alerts.isNotEmpty) {
      _fitBoundsToAlerts();
    }
  }

  // 🚁 Tải danh sách Drone từ Server
  Future<void> _loadDrones() async {
    if (!mounted) return;
    await context.read<MapProvider>().reloadDrones();
  }

  // Tự động zoom để hiển thị tất cả markers
  void _fitBoundsToAlerts() {
    if (_alerts.isEmpty) return;

    double minLat = _alerts.first.latitude;
    double maxLat = _alerts.first.latitude;
    double minLon = _alerts.first.longitude;
    double maxLon = _alerts.first.longitude;

    for (var alert in _alerts) {
      if (alert.latitude < minLat) minLat = alert.latitude;
      if (alert.latitude > maxLat) maxLat = alert.latitude;
      if (alert.longitude < minLon) minLon = alert.longitude;
      if (alert.longitude > maxLon) maxLon = alert.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLon),
      LatLng(maxLat, maxLon),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSurvivalMode) {
      _showDrones = false;
      _showPrediction = false;
    }
    return Scaffold(
      backgroundColor: widget.isSurvivalMode ? Colors.black : ThemeConfig.darkBackground,
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, color: Colors.white),
            SizedBox(width: 8),
            Text('Bản đồ Cứu hộ & Ngập lụt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        backgroundColor: ThemeConfig.darkSurface,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Toggle Drone
          Row(
            children: [
              Icon(Icons.airplanemode_active_rounded,
                  size: 16,
                  color: _showDrones
                      ? const Color(0xFF0A84FF)
                      : Colors.white38),
              Switch(
                value: _showDrones,
                activeThumbColor: const Color(0xFF0A84FF),
                onChanged: (val) => setState(() => _showDrones = val),
              ),
            ],
          ),
          // Toggle AI Prediction
          Row(
            children: [
              const Text("AI",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent)),
              Switch(
                value: _showPrediction,
                activeThumbColor: Colors.blueAccent,
                onChanged: (val) {
                  setState(() => _showPrediction = val);
                  if (val && _predictiveReports.isNotEmpty) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.analytics, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    "🤖 AI đã tính toán: ${_predictiveReports.length} điểm có nguy cơ ngập lan rộng trong 3 giờ tới")),
                          ],
                        ),
                        backgroundColor: Colors.blueAccent,
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Bản đồ
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _defaultCenter,
                    initialZoom: 13.0,
                    interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all),
                  ),
                  children: [
                    if (!widget.isSurvivalMode)
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.floodsos.app',
                      ),
                    if (!widget.isSurvivalMode)
                      CircleLayer(circles: _buildHeatmapCircles()),
                    
                    // MarkerCluster thay vì MarkerLayer thường
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 40,
                        size: const Size(40, 40),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(50),
                        markers: _buildMarkers(),
                        builder: (context, markers) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: ThemeConfig.sosRed.withValues(alpha: 0.9),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                markers.length.toString(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Polyline dẫn đường tản cư an toàn
                    if (_safeRoute.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _safeRoute,
                            strokeWidth: 5.0,
                            color: Colors.blueAccent,
                            pattern: StrokePattern.dashed(segments: const [10.0, 5.0]),
                            borderStrokeWidth: 2.0,
                            borderColor: Colors.white,
                          )
                        ],
                      ),
                    
                    // Shelters Display Layer
                    MarkerLayer(markers: _buildSheltersMarkers()),

                    // ── DRONE LAYER ──────────────────
                    if (_showDrones && !widget.isSurvivalMode)
                      AnimatedBuilder(
                        animation: _droneHoverAnim,
                        builder: (_, __) => MarkerLayer(
                            markers: _buildDroneMarkers()),
                      ),
                  ],
                ),

                // Chú thích
                Positioned(
                    left: 12,
                    bottom: 24,
                    right: 80,
                    child: _buildLegend()),

                // Thông báo nếu không có alerts
                if (_alerts.isEmpty)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hiện chưa có yêu cầu cứu hộ nào trên bản đồ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Nút báo ngập
            FloatingActionButton.extended(
              heroTag: 'report',
              onPressed: _showReportBottomSheet,
              backgroundColor: ThemeConfig.sosRed,
              icon: const Icon(Icons.water_drop, color: Colors.white),
              label: const Text("BÁO NGẬP",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            // Nút về vị trí mặc định
            FloatingActionButton.small(
              heroTag: 'center',
              onPressed: () {
                if (_alerts.isNotEmpty) {
                  _fitBoundsToAlerts();
                } else {
                  _mapController.move(_defaultCenter, 13.0);
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.center_focus_strong, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'zoom_in',
              onPressed: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                    _mapController.camera.center, currentZoom + 1);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.add, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'zoom_out',
              onPressed: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                    _mapController.camera.center, currentZoom - 1);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.remove, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  List<CircleMarker> _buildHeatmapCircles() {
    List<CircleMarker> circles = [];

    // Thêm các vòng báo ngập thật
    circles.addAll(_reports.map((r) {
      Color color;
      double radius;
      if (r.severity == 'critical') {
        color = Colors.red;
        radius = 200.0;
      } else if (r.severity == 'medium') {
        color = Colors.orange;
        radius = 150.0;
      } else {
        color = Colors.yellow;
        radius = 100.0;
      }
      return CircleMarker(
        point: LatLng(r.lat, r.lon),
        color: color.withValues(alpha: 0.3),
        borderStrokeWidth: 2,
        borderColor: color.withValues(alpha: 0.5),
        useRadiusInMeter: true,
        radius: radius,
      );
    }));

    // Thêm vòng báo ngập dự báo (nếu bật toggle)
    if (_showPrediction) {
      circles.addAll(_predictiveReports.map((r) {
        return CircleMarker(
          point: LatLng(r.lat, r.lon),
          color: Colors.blueAccent.withValues(alpha: 0.2),
          borderStrokeWidth: 2,
          borderColor: Colors.blueAccent.withValues(alpha: 0.6),
          useRadiusInMeter: true,
          radius: 120.0,
        );
      }));
    }

    return circles;
  }

  // Tạo SOS markers từ dữ liệu thật
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    for (var alert in _alerts) {
      Color alertColor = _getAlertColor(alert);

      markers.add(
        Marker(
          point: LatLng(alert.latitude, alert.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showAlertDetails(alert),
            child: Container(
              decoration: BoxDecoration(
                color: alertColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: const Icon(Icons.sos, color: Colors.white, size: 26),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  // Tạo Shelter markers
  List<Marker> _buildSheltersMarkers() {
    return _shelters.map((s) {
      return Marker(
        point: LatLng(s.lat, s.lon),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Vùng an toàn: ${s.name} (Sức chứa: ${s.current}/${s.capacity})'),
              backgroundColor: ThemeConfig.safeGreen,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'CHỈ ĐƯỜNG',
                textColor: Colors.white,
                onPressed: () => _calculateSafeRouteToShelter(s),
              ),
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(Icons.house_siding_rounded, color: Colors.black, size: 24),
          )
        )
      );
    }).toList();
  }

  // Thuật toán giả lập dẫn đường né ngập lụt
  void _calculateSafeRouteToShelter(ShelterModel targetShelter) {
    // Demo vị trí người dùng đang ở Phường Phú Hội (gần trung tâm)
    const startPos = LatLng(16.4600, 107.5950); 
    final endPos = LatLng(targetShelter.lat, targetShelter.lon);

    List<LatLng> route = [startPos];

    // Thuật toán Mock: Bẻ cong đường đi qua 2 điểm trung gian để vòng qua tâm ngập
    // Tìm điểm giữa (Midpoint)
    final midLat = (startPos.latitude + endPos.latitude) / 2;
    final midLon = (startPos.longitude + endPos.longitude) / 2;

    // Tính vector chỉ phương (dLat, dLon)
    final dLat = endPos.latitude - startPos.latitude;
    final dLon = endPos.longitude - startPos.longitude;
    
    // Tạo điểm Detour 1 (Né ra xa theo hướng vuông góc vector)
    double detour1Lat = midLat - dLon * 0.4;
    double detour1Lon = midLon + dLat * 0.4;

    // Tạo điểm Detour 2 (Vòng về lại)
    double detour2Lat = midLat + dLat * 0.2 - dLon * 0.2;
    double detour2Lon = midLon + dLon * 0.2 + dLat * 0.2;

    route.add(LatLng(detour1Lat, detour1Lon));
    route.add(LatLng(detour2Lat, detour2Lon));
    route.add(endPos);

    setState(() {
      _safeRoute = route;
    });

    // Zoom camera để bao quát toàn bộ tuyến đường
    final bounds = LatLngBounds.fromPoints(route);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60.0),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Đã tìm thấy lối thoát an toàn, tránh 2 điểm ngập lụt!'),
      backgroundColor: Colors.blueAccent,
    ));
  }

  // ══════════════════════════════════════════════
  // 🚁 XÂY DỰNG DRONE MARKERS VỚI ANIMATION
  // ══════════════════════════════════════════════
  List<Marker> _buildDroneMarkers() {
    return _drones.map((drone) {
      final isBusy = drone.status == 'busy';
      final droneColor = isBusy
          ? const Color(0xFF0A84FF) // Xanh neon khi đang bay
          : const Color(0xFF30D158); // Xanh lá khi đang đậu

      // Offset nhảy theo animation
      final hoverOffset = _droneHoverAnim.value;

      return Marker(
        point: LatLng(drone.latitude, drone.longitude),
        width: 60,
        height: 70,
        child: GestureDetector(
          onTap: () => _showDroneDetails(drone),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drone Icon với animation nhấp nhô
              Transform.translate(
                offset: Offset(0, hoverOffset),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vầng sáng phía sau
                    if (isBusy)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: droneColor.withValues(alpha: 0.15),
                          boxShadow: [
                            BoxShadow(
                              color: droneColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            )
                          ],
                        ),
                      ),
                    // Thân drone
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C2E),
                        shape: BoxShape.circle,
                        border: Border.all(color: droneColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: droneColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.airplanemode_active_rounded,
                        color: droneColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // Label ID drone
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2E).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: droneColor.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  drone.id,
                  style: TextStyle(
                    color: droneColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Modal chi tiết Drone ─────────────────────
  void _showDroneDetails(DroneModel drone) {
    final isBusy = drone.status == 'busy';
    final statusColor = isBusy
        ? const Color(0xFF0A84FF)
        : const Color(0xFF30D158);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Icon(Icons.airplanemode_active_rounded,
                      color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drone.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBusy ? 'ĐANG XUẤT KÍCH' : 'SẴN SÀNG',
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),

            // Thông số
            _buildInfoRow('📍', 'Vị trí',
                '${drone.latitude.toStringAsFixed(4)}, ${drone.longitude.toStringAsFixed(4)}'),
            _buildInfoRow('🔋', 'Pin', '${drone.battery}%'),
            _buildInfoRow('🎯', 'Mục tiêu',
                drone.targetId ?? 'Không (đang đậu tại căn cứ)'),
            const SizedBox(height: 16),

            // Battery bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pin: ${drone.battery}%',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: drone.battery / 100.0,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      drone.battery > 50
                          ? const Color(0xFF30D158)
                          : drone.battery > 20
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportBottomSheet() {
    String selectedSeverity = 'medium';
    String description = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20),
            decoration: const BoxDecoration(
              color: ThemeConfig.darkSurface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Báo Cáo Điểm Ngập",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: selectedSeverity,
                  dropdownColor: ThemeConfig.darkBackground,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                        value: 'low',
                        child: Text("Ngập nhẹ (Mắt cá chân) - Vàng")),
                    DropdownMenuItem(
                        value: 'medium',
                        child: Text("Ngập vừa (Nửa bánh xe) - Cam")),
                    DropdownMenuItem(
                        value: 'critical',
                        child: Text("Ngập nặng (Lút yên xe) - Đỏ")),
                  ],
                  onChanged: (val) =>
                      setModalState(() => selectedSeverity = val!),
                  decoration: const InputDecoration(
                    labelText: 'Mức độ',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Mô tả thêm (Tùy chọn)',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => description = val,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _submitReport(selectedSeverity, description);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.sosRed,
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text("GỬI BÁO CÁO NHANH",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _submitReport(String severity, String description) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final random = Random();
    final List<LatLng> hueLocations = [
      const LatLng(16.4690, 107.5760),
      const LatLng(16.4950, 107.5600),
      const LatLng(16.4735, 107.6072),
      const LatLng(16.4800, 107.6100),
      const LatLng(16.4526, 107.5912),
      const LatLng(16.4590, 107.5780),
      const LatLng(16.4534, 107.5445),
    ];
    final target = hueLocations[random.nextInt(hueLocations.length)];

    final success = await _apiService.sendFloodReport({
      'lat': target.latitude,
      'lon': target.longitude,
      'severity': severity,
      'description': description
    });

    if (!mounted) return;
    Navigator.pop(context); // Tắt loading

    if (success) {
      _loadAlerts();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã cập nhật điểm ngập lên bản đồ cộng đồng!')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lỗi gửi báo cáo!')));
    }
  }

  Color _getAlertColor(SOSAlertModel alert) {
    if (alert.status == 'critical' ||
        alert.waterLevel == 'Khẩn cấp' ||
        alert.waterLevel == 'Cao') {
      return Colors.red;
    } else if (alert.status == 'warning' || alert.waterLevel == 'Trung bình') {
      return Colors.orange;
    }
    return Colors.green;
  }

  void _showAlertDetails(SOSAlertModel alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2E3B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getAlertColor(alert),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sos, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS từ ${alert.name.isEmpty ? "Người dùng" : alert.name}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        alert.status == 'critical'
                            ? '🔴 ĐANG NGUY CẤP'
                            : '🟠 Cần hỗ trợ',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),
            _buildInfoRow('📍', 'Vị trí',
                '${alert.latitude.toStringAsFixed(5)}, ${alert.longitude.toStringAsFixed(5)}'),
            _buildInfoRow('📞', 'Số điện thoại',
                alert.phone.isEmpty ? 'Không có' : alert.phone),
            _buildInfoRow('👥', 'Số người', '${alert.peopleCount ?? '?'} người'),
            _buildInfoRow('🌊', 'Mức nước', alert.waterLevel ?? 'Chưa rõ'),
            _buildInfoRow('🕐', 'Thời gian', _formatTime(alert.createdAt)),
            if (alert.message != null && alert.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💬 Lời nhắn:',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12)),
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
                    icon: const Icon(Icons.map),
                    label: const Text('Chỉ đường'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                if (alert.phone.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.call),
                      label: const Text('Gọi điện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📌 Chú giải',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Điểm SOS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          _buildLegendItem(Colors.red, 'Nguy cấp'),
          _buildLegendItem(Colors.orange, 'Cảnh báo'),
          _buildLegendItem(Colors.green, 'An toàn'),
          const Divider(),
          const Text('Vùng An Toàn',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          _buildLegendItem(Colors.amber, 'Trạm trú ẩn (Shelter)'),
          const Divider(),
          const Text('Cộng đồng báo ngập',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          _buildLegendItem(
              Colors.red.withValues(alpha: 0.5), 'Ngập lút yên xe'),
          _buildLegendItem(
              Colors.orange.withValues(alpha: 0.5), 'Ngập nửa bánh xe'),
          _buildLegendItem(
              Colors.yellow.withValues(alpha: 0.5), 'Ngập lút mắt cá'),
          if (_showDrones) ...[
            const Divider(),
            const Text('Drone giám sát',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            _buildLegendItem(
                const Color(0xFF30D158), 'Drone sẵn sàng'),
            _buildLegendItem(
                const Color(0xFF0A84FF), 'Drone đang xuất kích'),
          ],
          if (_showPrediction) ...[
            const Divider(),
            _buildLegendItem(
                Colors.blueAccent.withValues(alpha: 0.5),
                'AI Dự báo (${_predictiveReports.length} điểm)'),
          ]
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[400])),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.white),
            ),
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
