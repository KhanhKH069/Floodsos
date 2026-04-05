// lib/services/in_app_notification_service.dart
// In-App Notification Banner — thay thế Firebase Push Notification
// Dùng Flutter Overlay để hiển thị drop-down banner từ trên đỉnh màn hình
// Không cần Firebase, không cần chứng chỉ, chạy 100% on-device

import 'dart:async';
import 'package:flutter/material.dart';

// Enum loại thông báo để chọn màu sắc & icon
enum NotificationType { sos, report, drone, info }

class InAppNotificationService {
  // Singleton pattern
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  OverlayEntry? _currentOverlay;
  Timer? _dismissTimer;

  // ─────────────────────────────────────────────
  // ENTRY POINT: Gọi hàm này để show banner
  // ─────────────────────────────────────────────
  void show(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
  }) {
    // Đóng banner cũ nếu đang hiện
    dismiss();

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (ctx) => _NotificationBanner(
        title: title,
        message: message,
        type: type,
        onDismiss: dismiss,
        onTap: () {
          dismiss();
          onTap?.call();
        },
      ),
    );

    overlay.insert(_currentOverlay!);

    // Auto-dismiss sau [duration]
    _dismissTimer = Timer(duration, dismiss);
  }

  void dismiss() {
    _dismissTimer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  // ─────────────────────────────────────────────
  // STATIC HELPERS — show từng loại event nhanh
  // ─────────────────────────────────────────────
  static void showSOS(BuildContext context, {String? detail}) {
    InAppNotificationService().show(
      context,
      title: '🚨 SOS Khẩn Cấp!',
      message: detail ?? 'Có người cần cứu hộ vừa gửi tín hiệu SOS mới.',
      type: NotificationType.sos,
    );
  }

  static void showFloodReport(BuildContext context, {String? detail}) {
    InAppNotificationService().show(
      context,
      title: '🌊 Điểm Ngập Mới',
      message: detail ?? 'Cộng đồng vừa báo cáo một điểm ngập lụt mới.',
      type: NotificationType.report,
    );
  }

  static void showDroneUpdate(BuildContext context, {String? detail}) {
    InAppNotificationService().show(
      context,
      title: '🚁 Drone Đã Xuất Kích',
      message: detail ?? 'Drone đang được triển khai đến vị trí mục tiêu.',
      type: NotificationType.drone,
      duration: const Duration(seconds: 4),
    );
  }

  static void showInfo(BuildContext context, String title, String message) {
    InAppNotificationService().show(
      context,
      title: title,
      message: message,
      type: NotificationType.info,
    );
  }
}

// ═══════════════════════════════════════════════
// WIDGET: Banner UI — slide-down từ trên xuống
// ═══════════════════════════════════════════════
class _NotificationBanner extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationBanner({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Slide từ trên xuống (từ -1.0 → 0.0)
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    ));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0, 0.4)),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Màu sắc theo loại
  Color get _accentColor {
    switch (widget.type) {
      case NotificationType.sos:
        return const Color(0xFFFF3B30);
      case NotificationType.report:
        return const Color(0xFFFF9F0A);
      case NotificationType.drone:
        return const Color(0xFF0A84FF);
      case NotificationType.info:
        return const Color(0xFF30D158);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case NotificationType.sos:
        return Icons.warning_rounded;
      case NotificationType.report:
        return Icons.water_drop_rounded;
      case NotificationType.drone:
        return Icons.airplanemode_active_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 0),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Glow background dải màu bên trái
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(color: _accentColor),
                    ),

                    // Nội dung chính
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon container
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_icon, color: _accentColor, size: 22),
                          ),
                          const SizedBox(width: 12),

                          // Title + message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Nút đóng
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withValues(alpha: 0.4),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
