import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/socket_service.dart';
import '../services/tracking_service.dart';
import '../services/udp_mesh_service.dart';

class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  final MapController _mapController = MapController();
  
  // deviceId -> List của các object Point
  final Map<String, List<Map<String, dynamic>>> _deviceTrails = {};
  
  StreamSubscription? _meshSub;
  bool _showEvacuees = true;
  bool _showRescuers = true;
  bool _isMeshActive = false;

  @override
  void initState() {
    super.initState();
    _initSocketListener();
    _initMeshRadarListener();
  }

  Future<void> _initMeshRadarListener() async {
    // Bật Radar nội bộ cho máy Admin
    await UdpMeshService().start();
    setState(() => _isMeshActive = true);

    _meshSub = UdpMeshService().onTrackingDataReceived.listen((data) {
      _handleIncomingLocation(data);
    });
  }

  void _initSocketListener() {
    final socket = SocketService().socket;
    if (socket == null) return;
    
    if (!socket.connected) {
      socket.connect();
    }

    socket.on('tracking_update', (data) {
      _handleIncomingLocation(data);
    });

    socket.on('tracking_sync_offline', (data) {
      _handleOfflineSync(data);
    });
  }

  void _handleIncomingLocation(dynamic data) {
    if (data == null || data['deviceId'] == null) return;
    final deviceId = data['deviceId'];

    setState(() {
      if (!_deviceTrails.containsKey(deviceId)) {
        _deviceTrails[deviceId] = [];
      }
      
      // Chèn điểm mới
      _deviceTrails[deviceId]!.add(Map<String, dynamic>.from(data));
      
      // Giới hạn độ dài trail (chỉ giữ 50 điểm gần nhất tránh nặng map)
      if (_deviceTrails[deviceId]!.length > 50) {
        _deviceTrails[deviceId]!.removeAt(0);
      }
    });
  }

  void _handleOfflineSync(dynamic data) {
    if (data == null || data['deviceId'] == null || data['trackingData'] == null) return;
    final deviceId = data['deviceId'];
    final bulkData = List<Map<String, dynamic>>.from(data['trackingData']);

    setState(() {
      if (!_deviceTrails.containsKey(deviceId)) {
        _deviceTrails[deviceId] = [];
      }
      _deviceTrails[deviceId]!.addAll(bulkData);

      // Xóa bớt điểm nếu quá dài (chỉ giữ 100 điểm cho offline sync)
      while (_deviceTrails[deviceId]!.length > 100) {
        _deviceTrails[deviceId]!.removeAt(0);
      }
    });
  }

  @override
  void dispose() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.off('tracking_update');
      socket.off('tracking_sync_offline');
    }
    _meshSub?.cancel();
    UdpMeshService().stop();
    super.dispose();
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    final now = DateTime.now();

    for (var deviceId in _deviceTrails.keys) {
      final trail = _deviceTrails[deviceId]!;
      if (trail.isEmpty) continue;

      final latest = trail.last;
      final role = latest['role'] == TrackingRole.rescuer.name ? 'rescuer' : 'evacuee';

      if (role == 'evacuee' && !_showEvacuees) continue;
      if (role == 'rescuer' && !_showRescuers) continue;

      final lat = latest['lat'];
      final lon = latest['lon'];
      final timestamp = DateTime.tryParse(latest['timestamp'] ?? '') ?? DateTime.now();
      
      // Nếu offline quá 5 phút -> đổi màu marker xám
      final isOffline = now.difference(timestamp).inMinutes > 5;

      Color markerColor;
      IconData markerIcon;

      if (role == 'rescuer') {
        markerColor = isOffline ? Colors.grey : Colors.blueAccent;
        markerIcon = Icons.shield;
      } else {
        markerColor = isOffline ? Colors.grey : Colors.orangeAccent;
        markerIcon = Icons.directions_run;
      }

      markers.add(
        Marker(
          point: LatLng(lat, lon),
          width: 50,
          height: 60,
          child: GestureDetector(
            onTap: () => _showDeviceDetails(latest, isOffline),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: latest['networkType'] == 'mesh' ? 4 : 2),
                    boxShadow: [
                      if (latest['networkType'] == 'mesh')
                        BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.8), blurRadius: 10, spreadRadius: 2)
                      else  
                        BoxShadow(color: markerColor.withValues(alpha: 0.5), blurRadius: 6),
                    ],
                  ),
                  child: Icon(
                    latest['networkType'] == 'mesh' ? Icons.wifi_tethering : markerIcon, 
                    color: latest['networkType'] == 'mesh' ? Colors.yellowAccent : Colors.white, 
                    size: latest['networkType'] == 'mesh' ? 18 : 20
                  ),
                ),
                // Hiển thị tên nhỏ bên dưới
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    latest['name'] ?? 'Khách',
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  List<Polyline> _buildTrails() {
    final List<Polyline> polylines = [];
    for (var deviceId in _deviceTrails.keys) {
      final trail = _deviceTrails[deviceId]!;
      if (trail.length < 2) continue;

      final role = trail.last['role'] == TrackingRole.rescuer.name ? 'rescuer' : 'evacuee';
      
      if (role == 'evacuee' && !_showEvacuees) continue;
      if (role == 'rescuer' && !_showRescuers) continue;

      final points = trail.map((pt) => LatLng(pt['lat'], pt['lon'])).toList();

      polylines.add(
        Polyline(
          points: points,
          strokeWidth: 3.0,
          color: role == 'rescuer' 
              ? Colors.blueAccent.withValues(alpha: 0.5) 
              : Colors.orangeAccent.withValues(alpha: 0.5),
        ),
      );
    }
    return polylines;
  }

  void _showDeviceDetails(Map<String, dynamic> data, bool isOffline) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2E3B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    data['role'] == TrackingRole.rescuer.name ? Icons.shield : Icons.directions_run,
                    color: data['role'] == TrackingRole.rescuer.name ? Colors.blueAccent : Colors.orangeAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          data['role'] == TrackingRole.rescuer.name ? 'Đội cứu hộ' : 'Người Sơ tán',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOffline ? Colors.grey[800] : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isOffline ? Colors.grey : Colors.green),
                    ),
                    child: Text(
                      isOffline ? 'Offline' : 'Online',
                      style: TextStyle(color: isOffline ? Colors.grey : Colors.green, fontSize: 12),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _detailMetric(Icons.speed, '${(data['speed'] ?? 0.0 * 3.6).toStringAsFixed(1)}', 'km/h'),
                  _detailMetric(Icons.battery_charging_full, '${data['battery'] ?? '?'}%', 'Pin'),
                  _detailMetric(Icons.timeline, '${_deviceTrails[data['deviceId']]?.length ?? 0}', 'Điểm nhớ'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _detailMetric(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2129),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TRẠM THEO DÕI HÀNH TRÌNH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Row(
              children: [
                Icon(Icons.wifi_tethering, size: 12, color: _isMeshActive ? Colors.yellowAccent : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _isMeshActive ? 'WLAN Mesh Radar / ON' : 'WLAN Mesh / OFF',
                  style: TextStyle(fontSize: 10, color: _isMeshActive ? Colors.yellowAccent : Colors.grey),
                ),
              ],
            )
          ],
        ),
        backgroundColor: const Color(0xFF2A2E3B),
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_deviceTrails.length} Đang kết nối',
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(19.3400, 105.7100), // Default to Hoàng Mai
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.floodsos',
              ),
              PolylineLayer(polylines: _buildTrails()),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          
          // Map Filters
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2E3B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _filterButton('Cứu hộ', Colors.blueAccent, _showRescuers, () {
                    setState(() => _showRescuers = !_showRescuers);
                  }),
                  const SizedBox(height: 8),
                  _filterButton('Sơ tán', Colors.orangeAccent, _showEvacuees, () {
                    setState(() => _showEvacuees = !_showEvacuees);
                  }),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _filterButton(String t, Color c, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: active ? c : Colors.transparent,
              border: Border.all(color: c),
              borderRadius: BorderRadius.circular(4),
            ),
            child: active ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
          ),
          const SizedBox(width: 8),
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
