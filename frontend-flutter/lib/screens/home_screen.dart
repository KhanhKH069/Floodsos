// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/in_app_notification_service.dart';
import '../config/theme_config.dart';
import 'chat_screen.dart';
import 'map_screen.dart';
import 'weather_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isSending = false;
  bool _isSurvivalMode = false;
  Position? _currentPosition;
  String _locationMessage = "Đang lấy vị trí...";
  bool _isLocationReady = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _msgController = TextEditingController();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioFilePath;

  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioRecorder.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _msgController.dispose();
    _mapController.dispose();
    super.dispose();
  }

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
      debugPrint("Lỗi dừng ghi âm: $e");
    }
  }

  Future<void> _determinePosition() async {
    // 🟢 Chế độ Demo: Lấy bừa 1 trong 7 tọa độ Huế
    final random = Random();
    final List<LatLng> hueLocations = [
      const LatLng(16.4690, 107.5760), // Đại Nội
      const LatLng(16.4950, 107.5600), // Hương Sơ
      const LatLng(16.4735, 107.6072), // Vĩ Dạ
      const LatLng(16.4800, 107.6100), // Phú Hậu
      const LatLng(16.4526, 107.5912), // An Cựu
      const LatLng(16.4590, 107.5780), // Ga Huế
      const LatLng(16.4534, 107.5445), // Thiên Mụ
    ];
    final target = hueLocations[random.nextInt(hueLocations.length)];

    Position mockPos = Position(
      latitude: target.latitude,
      longitude: target.longitude,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    setState(() {
      _currentPosition = mockPos;
      _locationMessage =
          "${mockPos.latitude.toStringAsFixed(4)}, ${mockPos.longitude.toStringAsFixed(4)} (Demo Huế)";
      _isLocationReady = true;
    });

    _mapController.move(target, 15.0);
  }

  Future<void> _sendSOS() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Nhập tên & SĐT!")));
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Chưa có vị trí!")));
      return;
    }
    setState(() => _isSending = true);
    final Map<String, String> data = {
      'lat': _currentPosition!.latitude.toString(),
      'lon': _currentPosition!.longitude.toString(),
      'name': _nameController.text,
      'phone': _phoneController.text,
      'message':
          _msgController.text.isEmpty ? "Cần cứu gấp!" : _msgController.text,
      'water_level': 'Chưa rõ',
      'people_count': '1'
    };
    bool success;
    if (_audioFilePath != null && File(_audioFilePath!).existsSync()) {
      success = await _apiService.sendVoiceSOS(data, _audioFilePath!);
    } else {
      success = await _apiService.sendTextSOS(data);
    }
    setState(() => _isSending = false);
    if (!mounted) return;
    if (success) {
      if (_audioFilePath != null) {
        try {
          File(_audioFilePath!).delete();
        } catch (_) {}
        setState(() => _audioFilePath = null);
      }
      // Hiển thị In-App Banner thay vì dialog (mượt mà hơn)
      if (!mounted) return;
      InAppNotificationService.showSOS(
        context,
        detail: 'Tín hiệu SOS đã được gửi! Đội cứu hộ đang di chuyển đến vị trí.',
      );
    } else {
      _showOfflineSMSDialog();
    }
  }

  void _showOfflineSMSDialog() {
    final lat = _currentPosition?.latitude.toStringAsFixed(5) ?? "";
    final lon = _currentPosition?.longitude.toStringAsFixed(5) ?? "";
    final name = _nameController.text.isNotEmpty ? _nameController.text : "Nạn nhân";
    final msg = _msgController.text.isNotEmpty ? _msgController.text : "Cần cứu hộ gấp!";
    final body = "SOS FloodSOS: $name dang o toa do $lat, $lon. Tinh trang: $msg. Can cuu ho khan cap!";
    final smsUri = Uri(scheme: 'sms', path: '112', queryParameters: {'body': body});

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ThemeConfig.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text("Lỗi Kết Nối Mạng", style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          "Không thể gửi tín hiệu SOS qua Internet. Bạn có muốn gửi thông tin tự động qua tin nhắn SMS (Ngoại tuyến) không?",
          style: TextStyle(color: ThemeConfig.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("HỦY", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              bool canLaunch = await canLaunchUrl(smsUri);
              if (!mounted) return;
              if (canLaunch) {
                await launchUrl(smsUri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Không thể mở ứng dụng nhắn tin!")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            icon: const Icon(Icons.sms, color: Colors.white),
            label: const Text("GỬI SMS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logoicnlab.png', width: 36, height: 36),
            const SizedBox(width: 10),
            const Text("FLOOD SOS",
                style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 2.0, 
                    color: Colors.white)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSurvivalMode ? Icons.battery_charging_full : Icons.battery_saver,
              color: _isSurvivalMode ? ThemeConfig.safeGreen : Colors.white54,
            ),
            tooltip: "Chế độ Sinh Tồn (Tiết kiệm pin)",
            onPressed: () {
              setState(() => _isSurvivalMode = !_isSurvivalMode);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_isSurvivalMode 
                  ? "Đã BẬT Chế độ Sinh Tồn. Đã tắt tải bản đồ nền để tiết kiệm pin tối đa." 
                  : "Đã TẮT Chế độ Sinh Tồn."),
                backgroundColor: _isSurvivalMode ? ThemeConfig.safeGreen : ThemeConfig.warningOrange,
                duration: const Duration(seconds: 3),
              ));
            },
          )
        ],
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'map',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => MapScreen(isSurvivalMode: _isSurvivalMode))),
            backgroundColor: ThemeConfig.sosRed.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: ThemeConfig.sosRed, width: 1.5),
            ),
            icon: const Icon(Icons.map, color: ThemeConfig.sosRed, size: 24),
            label: const Text("BẢN ĐỒ CỘNG ĐỒNG",
                style: TextStyle(
                    color: ThemeConfig.sosRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            elevation: 0,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'chat',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ChatScreen())),
            backgroundColor: ThemeConfig.infoCyan.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: ThemeConfig.infoCyan, width: 1.5),
            ),
            icon: const Icon(Icons.smart_toy, color: ThemeConfig.infoCyan, size: 24),
            label: const Text("HỎI TRỢ LÝ",
                style: TextStyle(
                    color: ThemeConfig.infoCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            elevation: 0,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'weather',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const WeatherScreen())),
            backgroundColor: ThemeConfig.warningOrange.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: ThemeConfig.warningOrange, width: 1.5),
            ),
            icon: const Icon(Icons.cloudy_snowing, color: ThemeConfig.warningOrange, size: 24),
            label: const Text("DỰ BÁO LŨ",
                style: TextStyle(
                    color: ThemeConfig.warningOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            elevation: 0,
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Instruction
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  "Điền thông tin và bấm nút đỏ để gọi cứu hộ khẩn cấp.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ThemeConfig.textSecondary, fontSize: 14),
                ),
              ),

              // Bản đồ Glassmorphism
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: ThemeConfig.darkSurface,
                  border: Border.all(
                      color: _isLocationReady ? ThemeConfig.safeGreen.withValues(alpha: 0.5) : Colors.white12,
                      width: 1.5),
                  boxShadow: _isLocationReady 
                    ? [BoxShadow(color: ThemeConfig.safeGreen.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 1)]
                    : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(16.4637, 107.5909),
                          initialZoom: 15.0,
                          interactionOptions: InteractionOptions(
                              flags: InteractiveFlag.all),
                        ),
                        children: [
                          if (!_isSurvivalMode)
                            TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.floodsos.app'),
                          if (_currentPosition != null)
                            MarkerLayer(markers: [
                              Marker(
                                  point: LatLng(_currentPosition!.latitude,
                                      _currentPosition!.longitude),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.my_location,
                                      color: ThemeConfig.sosRed, size: 40))
                            ]),
                        ],
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            )
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
                          child: Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16,
                                  color: _isLocationReady
                                      ? ThemeConfig.safeGreen
                                      : ThemeConfig.warningOrange),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(_locationMessage,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis)),
                              if (!_isLocationReady)
                                GestureDetector(
                                  onTap: _determinePosition,
                                  child: const Text("Thử lại",
                                      style: TextStyle(
                                          color: ThemeConfig.infoCyan,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Form nhập thông tin
              _buildCustomTextField(
                  _nameController, "Họ và tên", Icons.person, TextInputType.name),
              const SizedBox(height: 16),
              _buildCustomTextField(
                  _phoneController, "Số điện thoại", Icons.phone, TextInputType.phone),
              const SizedBox(height: 16),
              _buildCustomTextField(
                  _msgController, "Lời nhắn tình huống (tuỳ chọn)", Icons.edit_note, TextInputType.text),

              const SizedBox(height: 24),

              // Nút ghi âm
              OutlinedButton.icon(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                style: Theme.of(context).outlinedButtonTheme.style?.copyWith(
                  foregroundColor: WidgetStateProperty.all(_isRecording ? ThemeConfig.sosRed : ThemeConfig.infoCyan),
                  side: WidgetStateProperty.all(BorderSide(color: _isRecording ? ThemeConfig.sosRed : ThemeConfig.infoCyan, width: 1.5)),
                  overlayColor: WidgetStateProperty.all((_isRecording ? ThemeConfig.sosRed : ThemeConfig.infoCyan).withValues(alpha: 0.1)),
                ),
                icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic_none, size: 24),
                label: Text(
                  _isRecording ? "Đang ghi âm... Chạm để dừng" : "Ghi âm mô tả khẩn cấp",
                ),
              ),

              if (_audioFilePath != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeConfig.safeGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ThemeConfig.safeGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.audio_file,
                          color: ThemeConfig.safeGreen, size: 20),
                      const SizedBox(width: 10),
                      const Text("Bản ghi âm đã sẵn sàng",
                          style:
                              TextStyle(color: ThemeConfig.safeGreen, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _audioFilePath = null),
                        child: const Icon(Icons.delete_outline, color: ThemeConfig.sosRed, size: 22),
                      )
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Nút gửi SOS Hero
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeConfig.sosRed.withValues(alpha: 0.2 + (_pulseController.value * 0.4)),
                          blurRadius: 15 + (_pulseController.value * 15),
                          spreadRadius: _pulseController.value * 5,
                        )
                      ]
                    ),
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendSOS,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: ThemeConfig.sosGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.warning_rounded, size: 28, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text(
                                    "GỬI TÍN HIỆU SOS",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ),
                  );
                }
              ),

              const SizedBox(height: 80), // space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField(TextEditingController controller,
      String labelText, IconData icon, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
