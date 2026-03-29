// lib/screens/admin_map_screen.dart
// Màn hình bản đồ cứu hộ dành cho Admin — TRUNG TÂM ĐIỀU PHỐI.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_alert_model.dart';
import '../services/api_service.dart';
import '../utils/cached_tile_provider.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});
  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();
  Timer? _refreshTimer;

  final LatLng _defaultCenter = const LatLng(19.3400, 105.7100);

  List<SOSAlertModel> _alerts = [];
  bool _isLoading = true;
  bool _isMapReady = false;
  bool _showWeatherLayer = true;

  @override
  void initState() {
    super.initState();
    // Tự động làm mới bản đồ mỗi 30 giây — dùng Timer thực sự
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (_isMapReady && mounted) _loadData();
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final alerts = await _apiService.getSOSAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts
              .where((a) => a.latitude != 0.0 && a.longitude != 0.0)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'TRUNG TÂM ĐIỀU PHỐI',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Toggle lớp thời tiết
          IconButton(
            icon: Icon(_showWeatherLayer ? Icons.cloud : Icons.cloud_off),
            tooltip: 'Lớp thời tiết',
            onPressed: () => setState(() => _showWeatherLayer = !_showWeatherLayer),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 11.0,
              onMapReady: () {
                setState(() => _isMapReady = true);
                _loadData();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.floodsos.app',
                tileProvider: CachedTileProvider(),
              ),
              if (_showWeatherLayer)
                TileLayer(
                  urlTemplate:
                      'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=${ApiService.openWeatherApiKey}',
                  userAgentPackageName: 'com.floodsos.app',
                  tileProvider: CachedTileProvider(),
                ),

              // SOS MARKERS
              MarkerLayer(
                markers: _alerts.map((s) {
                  bool isSafe = s.status == 'safe';
                  return Marker(
                    point: LatLng(s.latitude, s.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showSOSDetails(s),
                      child: Icon(
                        isSafe ? Icons.check_circle : Icons.location_on,
                        color: isSafe ? Colors.green[700] : Colors.red,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────

  void _showSOSDetails(SOSAlertModel alert) {
    bool isSafe = alert.status == 'safe';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 420,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(children: [
              Icon(
                isSafe ? Icons.check_circle : Icons.warning,
                color: isSafe ? Colors.green : Colors.red,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSafe ? 'ĐÃ ĐƯỢC CỨU' : 'YÊU CẦU CỨU HỘ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSafe ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ]),
            const Divider(),
            _buildDetailRow(Icons.person,  'Họ tên:',  alert.name),
            _buildDetailRow(Icons.phone,   'SĐT:',     alert.phone),
            _buildDetailRow(Icons.water,   'Mức nước:', alert.waterLevel ?? 'Chưa rõ'),
            _buildDetailRow(Icons.groups,  'Số người:',alert.peopleCount ?? 'Chưa rõ'),
            _buildDetailRow(Icons.message, 'Lời nhắn:',alert.message ?? 'Không có'),
            const Spacer(),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makePhoneCall(alert.phone),
                  icon: const Icon(Icons.call),
                  label: const Text('GỌI ĐIỆN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (!isSafe)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmRescue(alert),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('XÁC NHẬN CỨU'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteSOS(alert),
                    icon: const Icon(Icons.delete),
                    label: const Text('XÓA TIN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Future<void> _confirmRescue(SOSAlertModel alert) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    final success = await _apiService.resolveSOS(alert.id);
    if (success) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xác nhận cứu hộ!')),
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSOS(SOSAlertModel alert) async {
    Navigator.pop(context);
    await _apiService.deleteSOS(alert.id);
    _loadData();
  }

  Future<void> _makePhoneCall(String phone) async {
    final url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
