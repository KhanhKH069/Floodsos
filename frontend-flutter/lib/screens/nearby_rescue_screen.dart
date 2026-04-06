// lib/screens/nearby_rescue_screen.dart
/// Màn hình cứu hộ cộng đồng — hiển thị khi có hàng xóm cần giúp.
/// Volunteer xem thông tin, bấm "Tôi có thể đến", và theo dõi tiến trình.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme_config.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../widgets/glass_widgets.dart';
import '../utils/cached_tile_provider.dart';

enum RescueStep { idle, accepted, arrived, completed }

class NearbyRescueScreen extends StatefulWidget {
  final NearbySosData sos;
  final String myName;
  final String myPhone;

  const NearbyRescueScreen({
    super.key,
    required this.sos,
    required this.myName,
    required this.myPhone,
  });

  @override
  State<NearbyRescueScreen> createState() => _NearbyRescueScreenState();
}

class _NearbyRescueScreenState extends State<NearbyRescueScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  RescueStep _step = RescueStep.idle;
  StreamSubscription<VolunteerUpdate>? _volSub;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Lắng nghe cập nhật volunteer từ server
    _volSub = SocketService.instance.volunteerStream.listen((update) {
      if (update.sosId == widget.sos.sosId && mounted) {
        if (update.status == 'completed') {
          setState(() => _step = RescueStep.completed);
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _volSub?.cancel();
    super.dispose();
  }

  Future<void> _acceptMission() async {
    setState(() => _step = RescueStep.accepted);
    // Thông báo qua HTTP + socket realtime
    await _api.volunteerAccept(
      sosId: widget.sos.sosId,
      volunteerName: widget.myName,
      volunteerPhone: widget.myPhone,
    );
    SocketService.instance.emitVolunteerAccepted(
      sosId: widget.sos.sosId,
      volunteerName: widget.myName,
      volunteerPhone: widget.myPhone,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã xác nhận! Bản đồ dẫn đường đang hiển thị.'),
          backgroundColor: ThemeConfig.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markArrived() async {
    setState(() => _step = RescueStep.arrived);
    await _api.volunteerArrive(sosId: widget.sos.sosId);
    SocketService.instance.emitVolunteerArrived(widget.sos.sosId);
  }

  Future<void> _markCompleted() async {
    setState(() => _step = RescueStep.completed);
    await _api.volunteerComplete(sosId: widget.sos.sosId);
    SocketService.instance.emitVolunteerCompleted(widget.sos.sosId);
  }

  String get _mobilityLabel {
    switch (widget.sos.mobilityStatus) {
      case 'needs_carry':
        return '♿ Cần được cõng/dẫn';
      case 'bedridden':
        return '🛏️ Không thể di chuyển';
      default:
        return '🚶 Có thể đi nhưng cần dẫn đường';
    }
  }

  Color get _stepColor {
    switch (_step) {
      case RescueStep.accepted:
        return const Color(0xFF1976D2);
      case RescueStep.arrived:
        return const Color(0xFFE65100);
      case RescueStep.completed:
        return const Color(0xFF2E7D32);
      default:
        return ThemeConfig.sosRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sos = widget.sos;
    final victimPos = LatLng(sos.lat, sos.lon);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: ThemeConfig.oceanGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white70),
                    ),
                    const Expanded(
                      child: Text(
                        '🤝 Cứu hộ cộng đồng',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Map mini ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: victimPos,
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          tileProvider: CachedTileProvider(),
                          userAgentPackageName: 'com.floodsos.app',
                        ),
                        MarkerLayer(markers: [
                          // Nạn nhân
                          Marker(
                            point: victimPos,
                            width: 56,
                            height: 56,
                            child: AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Transform.scale(
                                scale: _pulseAnim.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ThemeConfig.sosRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ThemeConfig.sosRed
                                            .withValues(alpha: 0.6),
                                        blurRadius: 16,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.sos,
                                      color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ),
                        ]),
                        // Vòng tròn 500m
                        CircleLayer(circles: [
                          CircleMarker(
                            point: victimPos,
                            radius: 500,
                            color: ThemeConfig.sosRed.withValues(alpha: 0.08),
                            borderColor:
                                ThemeConfig.sosRed.withValues(alpha: 0.3),
                            borderStrokeWidth: 1.5,
                            useRadiusInMeter: true,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Info Card ───────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GlassCard(
                    borderRadius: 24,
                    borderColor: _stepColor.withValues(alpha: 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Step
                        _buildStepBar(),
                        const SizedBox(height: 16),

                        // Victim info
                        _infoRow('👤', 'Người cần giúp', sos.name.isEmpty ? 'Người dùng' : sos.name),
                        _infoRow('📍', 'Khoảng cách', '${sos.distanceM}m từ bạn'),
                        _infoRow('🌊', 'Mực nước', sos.waterLevel.isEmpty ? 'Chưa rõ' : sos.waterLevel),
                        _infoRow('👥', 'Số người', '${sos.peopleCount} người'),
                        _infoRow('🦽', 'Tình trạng', _mobilityLabel),
                        if (sos.message.isNotEmpty)
                          _infoRow('💬', 'Lời nhắn', sos.message),

                        const Divider(height: 24, color: ThemeConfig.glassBorder),

                        // Action buttons
                        if (_step == RescueStep.idle) ...[
                          _actionBtn(
                            icon: Icons.handshake,
                            label: 'Tôi có thể giúp!',
                            color: const Color(0xFF1B5E20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: _acceptMission,
                          ),
                          const SizedBox(height: 10),
                          if (sos.phone.isNotEmpty)
                            _outlineBtn(
                              icon: Icons.phone,
                              label: 'Gọi cho họ trước',
                              onTap: () async {
                                final url = Uri(scheme: 'tel', path: sos.phone);
                                if (await canLaunchUrl(url)) await launchUrl(url);
                              },
                            ),
                        ],

                        if (_step == RescueStep.accepted) ...[
                          _statusBanner('🏃 Đang trên đường đến...', const Color(0xFF1565C0)),
                          const SizedBox(height: 12),
                          _actionBtn(
                            icon: Icons.location_on,
                            label: 'Mở Google Maps dẫn đường',
                            color: Colors.blue.shade800,
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade700, Colors.blue.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () async {
                              final url = Uri.parse(
                                'https://www.google.com/maps/dir/?api=1'
                                '&destination=${sos.lat},${sos.lon}&travelmode=walking',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          _actionBtn(
                            icon: Icons.check_circle,
                            label: 'Tôi đã đến nơi ✅',
                            color: const Color(0xFFE65100),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: _markArrived,
                          ),
                          if (sos.phone.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _outlineBtn(
                              icon: Icons.phone,
                              label: 'Gọi: ${sos.phone}',
                              onTap: () async {
                                final url = Uri(scheme: 'tel', path: sos.phone);
                                if (await canLaunchUrl(url)) await launchUrl(url);
                              },
                            ),
                          ],
                        ],

                        if (_step == RescueStep.arrived) ...[
                          _statusBanner('📍 Đã đến nơi — đang dẫn đến chỗ an toàn', const Color(0xFFE65100)),
                          const SizedBox(height: 12),
                          _actionBtn(
                            icon: Icons.home,
                            label: 'Đã đưa đến nơi an toàn 🎉',
                            color: const Color(0xFF2E7D32),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: _markCompleted,
                          ),
                        ],

                        if (_step == RescueStep.completed) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                              ),
                            ),
                            child: const Column(
                              children: [
                                Text('🎉', style: TextStyle(fontSize: 40)),
                                SizedBox(height: 8),
                                Text(
                                  'Cảm ơn bạn đã giúp đỡ!',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'SOS đã được đánh dấu hoàn thành.\nBạn là người hùng cộng đồng! 🌟',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _outlineBtn(
                            icon: Icons.arrow_back,
                            label: 'Quay về',
                            onTap: () => Navigator.of(context)
                                .popUntil((r) => r.isFirst),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBar() {
    final steps = ['Chờ', 'Nhận', 'Đến nơi', 'Hoàn thành'];
    final currentIndex = _step.index;
    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= currentIndex;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _stepColor : ThemeConfig.glassWhite,
                  border: Border.all(
                    color: done ? _stepColor : ThemeConfig.glassBorder,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                steps[i],
                style: TextStyle(
                  color: done ? Colors.white : Colors.white38,
                  fontSize: 10,
                  fontWeight: done ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (i < steps.length - 1)
                Positioned(
                  top: 14,
                  child: Container(
                    height: 2,
                    color: done ? _stepColor : ThemeConfig.glassBorder,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _statusBanner(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  color: ThemeConfig.tealLight, fontSize: 13)),
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

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeConfig.teal),
          color: ThemeConfig.teal.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ThemeConfig.teal, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: ThemeConfig.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
