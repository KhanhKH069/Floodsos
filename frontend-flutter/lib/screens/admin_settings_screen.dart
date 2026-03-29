// lib/screens/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _autoRefreshEnabled = true;
  bool _weatherLayerDefault = true;
  bool _soundAlerts = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFF1E2129),
      appBar: AppBar(
        title: const Text('CÀI ĐẶT HỆ THỐNG',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF242836),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Admin Info ──────────────────────────────────────────
          _sectionTitle('Thông tin tài khoản'),
          _infoCard(
            children: [
              _infoRow(Icons.person, 'Tên đăng nhập',
                  auth.user?.email ?? '—'),
              const Divider(color: Colors.white12, height: 1),
              _infoRow(Icons.badge_outlined, 'Họ tên',
                  auth.user?.name ?? '—'),
              const Divider(color: Colors.white12, height: 1),
              _infoRow(Icons.admin_panel_settings_outlined, 'Vai trò',
                  auth.user?.role.toUpperCase() ?? 'ADMIN'),
            ],
          ),

          const SizedBox(height: 20),

          // ─── Server Info ─────────────────────────────────────────
          _sectionTitle('Cấu hình máy chủ'),
          _infoCard(
            children: [
              _infoRow(
                  Icons.dns_outlined, 'Backend URL', ApiService.baseUrl),
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.copy_outlined,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Sao chép URL',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: ApiService.baseUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã sao chép URL!')),
                        );
                      },
                      child: const Text('Sao chép',
                          style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── Display Settings ─────────────────────────────────────
          _sectionTitle('Tùy chọn hiển thị'),
          _infoCard(
            children: [
              _toggleRow(
                Icons.refresh,
                'Tự động làm mới bản đồ',
                'Làm mới dữ liệu SOS mỗi 30 giây',
                _autoRefreshEnabled,
                (v) => setState(() => _autoRefreshEnabled = v),
              ),
              const Divider(color: Colors.white12, height: 1),
              _toggleRow(
                Icons.cloud_outlined,
                'Layer thời tiết mặc định',
                'Hiện lớp mưa khi mở bản đồ',
                _weatherLayerDefault,
                (v) => setState(() => _weatherLayerDefault = v),
              ),
              const Divider(color: Colors.white12, height: 1),
              _toggleRow(
                Icons.notifications_outlined,
                'Âm thanh cảnh báo SOS',
                'Phát âm thanh khi có SOS mới',
                _soundAlerts,
                (v) => setState(() => _soundAlerts = v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── About ───────────────────────────────────────────────
          _sectionTitle('Thông tin ứng dụng'),
          _infoCard(
            children: [
              _infoRow(Icons.info_outline, 'Phiên bản', '1.0.0+admin'),
              const Divider(color: Colors.white12, height: 1),
              _infoRow(Icons.code_outlined, 'Nền tảng', 'Flutter / Dart'),
              const Divider(color: Colors.white12, height: 1),
              _infoRow(Icons.security, 'AI Engine',
                  'LightGBM Edge (flood_ai_core)'),
            ],
          ),

          const SizedBox(height: 28),

          // ─── Logout ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                auth.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất khỏi hệ thống Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E3B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
