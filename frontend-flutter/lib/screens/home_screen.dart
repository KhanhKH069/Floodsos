// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../providers/location_provider.dart';

import '../services/api_service.dart';
import '../widgets/weather_info_widget.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/tracking_broadcaster_widget.dart';
import '../config/theme_config.dart';
import 'chat_screen.dart';
import 'map_screen.dart';
import 'weather_screen.dart';
import 'login_screen.dart';
import 'sos_routing_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ─── Services ──────────────────────────────────────────
  final ApiService _apiService = ApiService();

  // ─── State ─────────────────────────────────────────────
  bool _isSending = false;
  Position? _currentPosition;
  String _locationMessage = "Đang lấy vị trí...";
  bool _isLocationReady = false;
  bool _isSimulated = false;          // đang dùng vị trí giả lập Nghệ An
  int _currentTab = 0;

  // ─── Form ──────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _msgController = TextEditingController();

  // ─── Audio ─────────────────────────────────────────────
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioFilePath;

  // ─── Map ───────────────────────────────────────────────
  final MapController _mapController = MapController();

  // ─── Animations ────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _ripple1Ctrl;
  late AnimationController _ripple2Ctrl;

  @override
  void initState() {
    super.initState();
    // Đợi frame đầu tiên build xong (map widget sẵn sàng) rồi mới lấy vị trí
    WidgetsBinding.instance.addPostFrameCallback((_) => _determinePosition());

    // Pulse scale on SOS button
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Ripple rings — staggered
    _ripple1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ripple2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    Future.delayed(
        const Duration(milliseconds: 600), () => _ripple2Ctrl.forward(from: 0));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ripple1Ctrl.dispose();
    _ripple2Ctrl.dispose();
    _audioRecorder.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _msgController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ─── Location ──────────────────────────────────────────
  Future<void> _determinePosition() async {
    // ── Trên Desktop (Windows/Linux/Mac): Windows Location Services
    // ── thường trả về vị trí IP không chính xác → dùng thẳng Nghệ An.
    if (!kIsWeb && Platform.isWindows) {
      _applyNgheAnFallback();
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _applyNgheAnFallback();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _applyNgheAnFallback();
      return;
    }
    try {
      Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      // Kiểm tra nếu tọa độ nằm ngoài Nghệ An (app demo) → dùng Nghệ An
      final inNgheAn = pos.latitude >= 18.5 && pos.latitude <= 20.0 &&
                       pos.longitude >= 104.0 && pos.longitude <= 106.5;
      if (!inNgheAn) {
        _applyNgheAnFallback();
        return;
      }
      setState(() {
        _currentPosition = pos;
        _locationMessage =
            "${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
        _isLocationReady = true;
        _isSimulated = false;
      });
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
    } catch (_) {
      _applyNgheAnFallback();
    }
  }

  /// Áp dụng ngay 1 trong 7 tọa độ Nghệ An (nhất quán cả session)
  void _applyNgheAnFallback() {
    final point = LocationProvider.sessionPoint;
    setState(() {
      _isSimulated = true;
      _locationMessage = '📍 ${point.name}';
      _isLocationReady = true;
    });
    _mapController.move(LatLng(point.latitude, point.longitude), 13.0);
  }

  // ─── Audio ─────────────────────────────────────────────
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        String path =
            '${dir.path}/sos_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
        const config = RecordConfig(encoder: AudioEncoder.aacLc);
        await _audioRecorder.start(config, path: path);
        setState(() {
          _isRecording = true;
          _audioFilePath = path;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Chưa cấp quyền Micro!")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Lỗi Micro!")));
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioFilePath = path;
      });
    } catch (e) {
      debugPrint("Lỗi dừng: $e");
    }
  }

  // ─── SOS ───────────────────────────────────────────────
  Future<void> _sendSOS() async {
    // 1. Phục hồi yêu cầu điền Name & Phone theo yêu cầu của User
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bắt buộc nhập Tên & SĐT để đội cứu hộ liên lạc!")),
      );
      return;
    }

    // 2. Nếu không có GPS thật → dùng điểm Nghệ An đã chọn cho session này
    double lat = _currentPosition?.latitude ?? LocationProvider.sessionPoint.latitude;
    double lon = _currentPosition?.longitude ?? LocationProvider.sessionPoint.longitude;

    setState(() => _isSending = true);
    Map<String, dynamic> result;
    if (_audioFilePath != null && File(_audioFilePath!).existsSync()) {
      result = await _apiService.sendVoiceSOS(
        deviceId: 'home',
        latitude: lat,
        longitude: lon,
        battery: 100,
        audioFilePath: _audioFilePath!,
        name: _nameController.text,
        phone: _phoneController.text,
        waterLevel: 'Chưa rõ',
        peopleCount: '1',
        message:
            _msgController.text.isEmpty ? 'Cần cứu gấp!' : _msgController.text,
      );
    } else {
      result = await _apiService.sendTextSOS({
        'lat': lat.toString(),
        'lon': lon.toString(),
        'name': _nameController.text,
        'phone': _phoneController.text,
        'message':
            _msgController.text.isEmpty ? 'Cần cứu gấp!' : _msgController.text,
        'water_level': 'Chưa rõ',
        'people_count': '1',
      });
    }
    setState(() => _isSending = false);
    if (result['success'] == true) {
      if (_audioFilePath != null) {
        try {
          File(_audioFilePath!).delete();
        } catch (_) {}
        setState(() => _audioFilePath = null);
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SOSRoutingResultScreen(
            lat: lat,
            lon: lon,
            urgencyProb: double.tryParse(result['urgency_prob']?.toString() ?? ''),
            isUrgent: result['is_urgent'] as bool?,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hoạt động Ngoại tuyến: Đã xếp hàng chờ gửi!'),
          backgroundColor: Colors.orange,
        ),
      );
      // Vẫn chuyển màn hình ở chế độ Offline thay vì kẹt lại
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SOSRoutingResultScreen(
            lat: lat,
            lon: lon,
            urgencyProb: 0.75, // Mock probability offline
            isUrgent: true,    // Mock status offline
          ),
        ),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.oceanDeep,
      body: Stack(
        children: [
          // Ocean gradient background
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: ThemeConfig.oceanGradient),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _buildTabBody(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Admin button (hidden, subtle)
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: const Icon(Icons.admin_panel_settings_outlined,
                  color: Colors.white24, size: 18),
            ),
          ),
          const Spacer(),
          // Logo + Title
          const Row(
            children: [
              Icon(Icons.water_drop, color: ThemeConfig.teal, size: 22),
              SizedBox(width: 8),
              Text(
                'FLOOD SOS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // GPS status dot
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: Icon(
              Icons.gps_fixed,
              size: 18,
              color: _isLocationReady ? ThemeConfig.teal : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const MapScreen();
      case 2:
        return const ChatScreen();
      case 3:
        return const WeatherScreen();
    }
    return const SizedBox.shrink();
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Weather glass card
          const GlassCard(
            padding: EdgeInsets.all(0),
            borderRadius: 20,
            margin: EdgeInsets.only(bottom: 16),
            child: WeatherInfoWidget(),
          ),

          // SOS Pulse Button
          _buildSOSButton(),

          const SizedBox(height: 24),

          // Form section
          const SectionLabel('Thông tin người gặp nạn'),
          GlassCard(
            borderRadius: 20,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Họ và Tên",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Số điện thoại",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Lời nhắn (tuỳ chọn)",
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                ),
              ],
            ),
          ),

          // Audio record pill
          const SectionLabel('Ghi âm mô tả'),
          _buildRecordPill(),
          const SizedBox(height: 24),

          // Mini map
          const SectionLabel('Vị trí của bạn'),
          _buildMiniMap(),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Image.asset('assets/images/logoo.png', height: 160, fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 180,
                height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple ring 1
                AnimatedBuilder(
                  animation: _ripple1Ctrl,
                  builder: (_, __) {
                    final v = _ripple1Ctrl.value;
                    return Opacity(
                      opacity: (1 - v).clamp(0, 0.5),
                      child: Container(
                        width: 90 + v * 80,
                        height: 90 + v * 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ThemeConfig.teal,
                            width: max(0.5, 2.5 - v * 2),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Ripple ring 2 (staggered)
                AnimatedBuilder(
                  animation: _ripple2Ctrl,
                  builder: (_, __) {
                    final v = _ripple2Ctrl.value;
                    return Opacity(
                      opacity: (1 - v).clamp(0, 0.4),
                      child: Container(
                        width: 90 + v * 70,
                        height: 90 + v * 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ThemeConfig.tealLight,
                            width: max(0.5, 2 - v * 2),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Main button
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: _isSending ? 1.0 : 1.0 + _pulseCtrl.value * 0.04,
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: _isSending ? null : _sendSOS,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isLocationReady
                              ? [
                                  const Color(0xFFEF5350),
                                  const Color(0xFFB71C1C)
                                ]
                              : [Colors.grey, Colors.grey.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: _isLocationReady
                            ? [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                )
                              ]
                            : [],
                      ),
                      child: _isSending
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sos, color: Colors.white, size: 34),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
              const SizedBox(width: 8),
              Expanded(
                child: Image.asset('assets/images/logoptit.png', height: 160, fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isSending
                ? 'Đang gửi...'
                : (_isLocationReady ? 'Nhấn để gửi SOS' : 'Đang định vị...'),
            style: TextStyle(
              color: _isLocationReady ? ThemeConfig.tealLight : Colors.white38,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordPill() {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: _isRecording ? ThemeConfig.teal : ThemeConfig.glassBorder,
      child: Column(
        children: [
          Listener(
            onPointerDown: (_) => _startRecording(),
            onPointerUp: (_) => _stopRecording(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: _isRecording ? ThemeConfig.teal : Colors.white70,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  _isRecording
                      ? "Đang ghi âm..."
                      : (_audioFilePath != null
                          ? "✓ Đã ghi âm — giữ để ghi lại"
                          : "Giữ để ghi âm tình trạng"),
                  style: TextStyle(
                    color: _isRecording ? ThemeConfig.teal : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_audioFilePath != null && !_isRecording) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 16),
              label: const Text("Xóa file ghi âm",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              onPressed: () => setState(() => _audioFilePath = null),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniMap() {
    // Xác định marker point để hiển thị
    final markerPoint = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : (_isSimulated
            ? LatLng(LocationProvider.sessionPoint.latitude,
                LocationProvider.sessionPoint.longitude)
            : null);

    return GlassCard(
      padding: const EdgeInsets.all(0),
      borderRadius: 20,
      borderColor: _isLocationReady
          ? (_isSimulated
              ? Colors.orange.withValues(alpha: 0.5)
              : ThemeConfig.teal.withValues(alpha: 0.5))
          : ThemeConfig.glassBorder,
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: SizedBox(
          height: 190,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: markerPoint ?? const LatLng(18.6796, 105.6813),
                  initialZoom: _isSimulated ? 13.0 : 15.0,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.floodsos.app',
                  ),
                  if (markerPoint != null)
                    MarkerLayer(markers: [
                      Marker(
                        point: markerPoint,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isSimulated ? Colors.orange : ThemeConfig.teal)
                                .withValues(alpha: 0.2),
                            border: Border.all(
                              color: _isSimulated ? Colors.orange : ThemeConfig.teal,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _isSimulated ? Icons.location_city : Icons.my_location,
                            color:
                                _isSimulated ? Colors.orange : ThemeConfig.teal,
                            size: 22,
                          ),
                        ),
                      )
                    ]),
                ],
              ),
              // Tracking Broadcaster
              const TrackingBroadcasterWidget(),
              // Badge NGHỆ AN khi dùng vị trí giả lập
              if (_isSimulated)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science_outlined,
                            size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Nghệ An – Phân tích',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              // GPS label overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSimulated ? Icons.location_city : Icons.location_on,
                        size: 13,
                        color: _isSimulated
                            ? Colors.orange
                            : (_isLocationReady
                                ? ThemeConfig.teal
                                : Colors.orange),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _locationMessage,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'SOS'),
      BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Bản đồ'),
      BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline), label: 'Hotline'),
      BottomNavigationBarItem(
          icon: Icon(Icons.cloud_outlined), label: 'Thời tiết'),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.oceanDeep.withValues(alpha: 0.98),
            ThemeConfig.oceanMid.withValues(alpha: 0.98),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(
          top: BorderSide(
            color: ThemeConfig.glassBorder,
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ThemeConfig.teal,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: items,
      ),
    );
  }
}
