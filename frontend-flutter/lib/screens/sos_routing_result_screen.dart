// lib/screens/sos_routing_result_screen.dart
//
// Hiển thị kết quả phân tích tuyến đường sau khi gửi SOS:
//   • Ngập THẤP → Self-Evacuation: chỉ đường dân đến điểm trú ẩn
//   • Ngập CAO  → Rescue Dispatch: kế hoạch cứu hộ từng chặng + xe/xuồng

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import '../services/api_service.dart';
import '../utils/route_helper.dart';
import '../utils/cached_tile_provider.dart';
import 'package:flutter/foundation.dart';
import '../services/offline_routing_service.dart';

class SOSRoutingResultScreen extends StatefulWidget {
  final double lat;
  final double lon;
  final double? urgencyProb;
  final bool? isUrgent;

  const SOSRoutingResultScreen({
    super.key,
    required this.lat,
    required this.lon,
    this.urgencyProb,
    this.isUrgent,
  });

  @override
  State<SOSRoutingResultScreen> createState() => _SOSRoutingResultScreenState();
}

class _SOSRoutingResultScreenState extends State<SOSRoutingResultScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _result;
  bool _isLoading = true;
  String? _error;

  // OFF-ROUTE TRACKING
  StreamSubscription<Position>? _positionStream;
  bool _isOffRoute = false;
  final FlutterTts _tts = FlutterTts();
  double? _currentLat;
  double? _currentLon;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.lat;
    _currentLon = widget.lon;
    _initTts();
    _analyze();
  }

  void _initTts() async {
    await _tts.setLanguage("vi-VN");
  }

  Future<void> _analyze([double? newLat, double? newLon]) async {
    if (newLat != null && newLon != null) {
      _currentLat = newLat;
      _currentLon = newLon;
    }

    setState(() { _isLoading = true; _error = null; });
    final networkData = await _api.analyzeRoute(_currentLat!, _currentLon!);
    if (!mounted) return;
    
    // Nếu rớt mạng (null), lập tức vọt sang Chip AI TFLite Offline
    final finalData = networkData ?? await OfflineRoutingService.getOfflineAIPath(_currentLat!, _currentLon!);
    
    // Lấy detail points (men theo đường) từ OSRM cho từng chặng
    if (finalData['segments'] != null) {
      final segs = finalData['segments'] as List;
      for (var seg in segs) {
        final from = seg['from_point'] as List?;
        final to   = seg['to_point']   as List?;
        if (from != null && to != null && from.length >= 2 && to.length >= 2) {
          final start = LatLng(double.tryParse(from[0].toString()) ?? 0.0, double.tryParse(from[1].toString()) ?? 0.0);
          final end = LatLng(double.tryParse(to[0].toString()) ?? 0.0, double.tryParse(to[1].toString()) ?? 0.0);
          if (start.latitude != end.latitude || start.longitude != end.longitude) {
            seg['detailed_points'] = await RouteHelper.getRoadRoute(start, end);
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _result  = finalData;
      _isLoading = false;
      _isOffRoute = false;
      if (_result == null) { // Vẫn null (Cực hiếm)
        _error = 'TFLite Model hỏng hoặc máy tải không nổi.';
      } else {
        _startNavigation();
      }
    });
  }

  void _startNavigation() {
    _positionStream?.cancel();
    
    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
      
      LocationSettings settings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        settings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          forceLocationManager: true,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Đang theo dõi lộ trình an toàn...",
            notificationTitle: "Flood SOS Đang Chạy Nền",
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        settings = AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        );
      } else {
        settings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        );
      }

      _positionStream = Geolocator.getPositionStream(locationSettings: settings)
          .listen((Position position) {
        if (_routePoints.isEmpty) return;
        
        LatLng myLoc = LatLng(position.latitude, position.longitude);

        double distance = RouteHelper.getMinDistanceFromRoute(myLoc, _routePoints);

        if (distance > 20.0 && !_isOffRoute) {
          setState(() { _isOffRoute = true; });
          _triggerOffRouteWarning(myLoc);
        } else if (distance <= 20.0 && _isOffRoute) {
          setState(() { _isOffRoute = false; });
        }
      });
    });
  }

  Future<void> _triggerOffRouteWarning(LatLng wrongLocation) async {
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000]); 
    }
    
    await _tts.speak("Cảnh báo, bạn đang đi chệch hướng lộ trình an toàn!");

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 BẠN ĐANG ĐI SAI ĐƯỜNG!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );

    _analyze(wrongLocation.latitude, wrongLocation.longitude);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _tts.stop();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool get _isHighFlood =>
      (_result?['flood_level'] == 'high') ||
      (_result?['flood_level'] == 'unknown' && (widget.isUrgent ?? false));

  Color _segmentColor(String level) {
    switch (level) {
      case 'heavy':    return Colors.red.shade700;
      case 'moderate': return Colors.orange.shade700;
      case 'low':      return Colors.yellow.shade800;
      default:         return Colors.green.shade600;
    }
  }

  String _segmentIcon(String level) {
    switch (level) {
      case 'heavy':    return '🔴';
      case 'moderate': return '🟠';
      case 'low':      return '🟡';
      default:         return '🟢';
    }
  }

  String _segmentLabel(String level) {
    switch (level) {
      case 'heavy':    return 'Ngập nặng';
      case 'moderate': return 'Ngập vừa';
      case 'low':      return 'Ngập nhẹ';
      default:         return 'Không ngập';
    }
  }

  List<LatLng> get _routePoints {
    final List<LatLng> allDetailed = [];
    if (_result?['segments'] != null) {
      for (var seg in _result!['segments']) {
        if (seg['detailed_points'] != null) {
          allDetailed.addAll(seg['detailed_points'] as List<LatLng>);
        }
      }
    }
    if (allDetailed.isNotEmpty) return allDetailed;

    final routeRaw = _result?['route'] as List?;
    if (routeRaw == null) return [];
    return routeRaw.map<LatLng>((pt) {
      final p = pt as List;
      return LatLng(double.tryParse(p[0].toString()) ?? 0.0, double.tryParse(p[1].toString()) ?? 0.0);
    }).toList();
  }

  List<dynamic> get _segments => (_result?['segments'] as List?) ?? [];

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isHigh = _isHighFlood;
    final Color accent    = isHigh ? Colors.red.shade700    : Colors.green.shade700;
    final Color bgTop     = isHigh ? const Color(0xFF3B0000) : const Color(0xFF003B1C);
    final String titleText = _isLoading
        ? 'Đang phân tích...'
        : isHigh
            ? '🚨 Kế Hoạch Cứu Hộ'
            : '✅ Đường Đến Nơi An Toàn';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: bgTop,
        foregroundColor: Colors.white,
        title: Text(titleText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Phân tích lại',
            onPressed: _analyze,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildResult(isHigh, accent),
    );
  }

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text('AI đang phân tích tuyến đường...',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Vị trí: ${_currentLat!.toStringAsFixed(5)}, ${_currentLon!.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 60),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _analyze,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );

  Widget _buildResult(bool isHigh, Color accent) {
    final summary = _result?['summary'] as String? ?? '';
    final floodProb = double.tryParse(_result?['flood_prob']?.toString() ?? '');
    final totalKm = double.tryParse(_result?['total_distance_km']?.toString() ?? '') ?? 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner chế độ ──────────────────────────────────────────────
          _buildModeBanner(isHigh, accent, floodProb),

          // ── Urgency badge nếu có ────────────────────────────────────────
          if (widget.urgencyProb != null)
            _buildUrgencyBadge(),

          // ── Bản đồ tuyến đường ─────────────────────────────────────────
          if (_routePoints.isNotEmpty)
            _buildMap(isHigh, accent),

          // ── Thông tin tổng tuyến ───────────────────────────────────────
          _buildRouteSummaryCard(isHigh, accent, totalKm, summary),

          // ── Chế độ THẤP: Thông tin shelter ────────────────────────────
          if (!isHigh && _result?['shelter'] != null)
            _buildShelterCard(accent),

          // ── Chế độ CAO: Info trạm cứu hộ ──────────────────────────────
          if (isHigh && _result?['rescue_base'] != null)
            _buildRescueBaseCard(accent),

          // ── Phân tích từng chặng ────────────────────────────────────────
          if (_segments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
              child: Text(
                isHigh ? '📍 Kế hoạch từng chặng cứu hộ' : '🗺️ Các chặng trên đường',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ..._segments.asMap().entries.map((e) => _buildSegmentCard(e.value, e.key)),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildModeBanner(bool isHigh, Color accent, double? floodProb) {
    final probText = floodProb != null
        ? ' (Xác suất ngập: ${(floodProb * 100).toStringAsFixed(0)}%)'
        : '';
    return Container(
      color: accent.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(isHigh ? Icons.emergency : Icons.directions_walk,
              color: accent, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHigh ? 'Ngập cao — Gọi đội cứu hộ' : 'Ngập thấp — Tự sơ tán',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  probText.trim(),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge() {
    final prob = widget.urgencyProb!;
    final urgent = widget.isUrgent ?? (prob >= 0.5);
    final color = urgent ? Colors.red.shade700 : Colors.green.shade700;
    return Container(
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        urgent
            ? '⚡ Độ khẩn cấp: ${(prob * 100).toStringAsFixed(0)}% — KHẨN CẤP'
            : '✅ Độ khẩn cấp: ${(prob * 100).toStringAsFixed(0)}% — Có thể kiểm soát',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildMap(bool isHigh, Color accent) {
    final points = _routePoints;
    if (points.isEmpty) return const SizedBox.shrink();

    final center = points[points.length ~/ 2];
    final sosPoint = LatLng(_currentLat!, _currentLon!);

    return SizedBox(
      height: 260,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12.5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.floodsos.app',
            tileProvider: CachedTileProvider(),
          ),
          // Vẽ route theo màu ngập từng chặng
          for (final seg in _segments)
            _buildSegmentPolyline(seg),
          // Fallback: toàn tuyến nếu không có segments
          if (_segments.isEmpty)
            PolylineLayer(
              polylines: [Polyline(points: points, color: accent, strokeWidth: 4)],
            ),
          MarkerLayer(markers: [
            // Điểm SOS (người cần cứu)
            Marker(
              point: sosPoint,
              width: 40, height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person_pin, color: Colors.white, size: 22),
              ),
            ),
            // Điểm đích (shelter hoặc trạm cứu về điểm SOS)
            if (points.isNotEmpty)
              Marker(
                point: points.last,
                width: 40, height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: isHigh ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    isHigh ? Icons.home_work : Icons.home,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSegmentPolyline(dynamic seg) {
    final from = seg['from_point'] as List?;
    final to   = seg['to_point']   as List?;
    if (from == null || to == null || from.length < 2 || to.length < 2) {
      return const SizedBox.shrink();
    }
    final level = seg['flood_level'] as String? ?? 'none';
    final color = _segmentColor(level);
    
    final detailPoints = seg['detailed_points'] as List<LatLng>?;

    return PolylineLayer(
      polylines: [
        Polyline(
          points: detailPoints ?? [
            LatLng(double.tryParse(from[0].toString()) ?? 0.0, double.tryParse(from[1].toString()) ?? 0.0),
            LatLng(double.tryParse(to[0].toString()) ?? 0.0, double.tryParse(to[1].toString()) ?? 0.0),
          ],
          color: color,
          strokeWidth: 5,
        ),
      ],
    );
  }

  Widget _buildRouteSummaryCard(bool isHigh, Color accent, double km, String summary) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tổng tuyến: ${km.toStringAsFixed(1)} km',
                style: TextStyle(
                    color: accent, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(summary,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildShelterCard(Color accent) {
    final sh = _result!['shelter'] as Map<String, dynamic>;
    final name = sh['name'] as String? ?? 'Điểm trú ẩn';
    final distParam = double.tryParse(sh['distance_km']?.toString() ?? '');
    final dist = distParam != null ? distParam.toStringAsFixed(1) : '?';
    final lat  = double.tryParse(sh['lat']?.toString() ?? '');
    final lon  = double.tryParse(sh['lon']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2A12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.home, color: Colors.green, size: 22),
              SizedBox(width: 8),
              Text('Điểm sơ tán đề xuất',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text('📍 $name  ($dist km)',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          if (lat != null && lon != null) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.map),
              label: const Text('Mở Google Maps'),
              onPressed: () => _openMaps(lat, lon, name),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRescueBaseCard(Color accent) {
    final rb = _result!['rescue_base'] as Map<String, dynamic>;
    final source = rb['source'] as String? ?? '';
    final srcLabel = source == 'base_json' ? 'Trạm cứu hộ' : 'Điểm xuất phát (shelter)';
    final lat = double.tryParse(rb['lat']?.toString() ?? '');
    final lon = double.tryParse(rb['lon']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  color: Colors.orange.shade400, size: 22),
              const SizedBox(width: 8),
              Text('Điểm xuất phát cứu hộ — $srcLabel',
                  style: TextStyle(
                      color: Colors.orange.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          if (lat != null && lon != null) ...[
            const SizedBox(height: 6),
            Text('Tọa độ: ${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          const Text(
            '👉 Đội cứu hộ xuất phát từ đây, đi theo tuyến dưới đây đến điểm SOS.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(dynamic seg, int index) {
    final level   = seg['flood_level']   as String? ?? 'none';
    final plan    = seg['plan']          as String? ?? '';
    final distParam = double.tryParse(seg['distance_km']?.toString() ?? '');
    final distKm  = distParam != null ? distParam.toStringAsFixed(2) : '?';
    final prob    = double.tryParse(seg['flood_prob_avg']?.toString() ?? '') ?? 0.0;
    final segColor = _segmentColor(level);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: segColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: segColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${_segmentIcon(level)} Chặng ${index + 1} — ${_segmentLabel(level)}',
                  style: TextStyle(
                    color: segColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text('$distKm km',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            // Thanh progress ngập
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: prob.clamp(0.0, 1.0),
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(segColor),
                minHeight: 6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'Xác suất ngập: ${(prob * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),
            // Phương án
            Text(plan,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Future<void> _openMaps(double lat, double lon, String label) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=walking');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không mở được Google Maps.')),
        );
      }
    }
  }
}
