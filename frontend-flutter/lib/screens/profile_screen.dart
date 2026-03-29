//lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';
import '../navigation/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ThemeConfig.oceanGradient),
      child: Consumer<AuthProvider>(
        builder: (context, provider, _) {
          final user = provider.user;
          if (user == null) {
            return const Center(
              child: Text('Chưa đăng nhập',
                  style: TextStyle(color: ThemeConfig.tealLight)),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildProfileHeader(user.name, user.email),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Account section
                      const SectionLabel('Tài khoản'),
                      GlassCard(
                        borderRadius: 20,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _menuItem(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              subtitle: user.email,
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.phone_outlined,
                              title: 'Số điện thoại',
                              subtitle: user.phone ?? 'Chưa cập nhật',
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.devices_outlined,
                              title: 'Thiết bị IoT',
                              subtitle: '2 thiết bị',
                              trailing: Icons.chevron_right,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Settings section
                      const SectionLabel('Cài đặt'),
                      GlassCard(
                        borderRadius: 20,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _switchItem(
                              icon: Icons.notifications_outlined,
                              title: 'Thông báo',
                              subtitle: 'Nhận cảnh báo khẩn cấp',
                              value: true,
                              onChanged: (_) {},
                            ),
                            _divider(),
                            _switchItem(
                              icon: Icons.location_on_outlined,
                              title: 'Vị trí',
                              subtitle: 'Cho phép truy cập vị trí',
                              value: true,
                              onChanged: (_) {},
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.language_outlined,
                              title: 'Ngôn ngữ',
                              subtitle: 'Tiếng Việt',
                              trailing: Icons.chevron_right,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // About section
                      const SectionLabel('Về ứng dụng'),
                      GlassCard(
                        borderRadius: 20,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _menuItem(
                              icon: Icons.info_outline,
                              title: 'Phiên bản',
                              subtitle: '2.0.0 — Calm Crisis UI',
                              onTap: () => _showAboutDialog(context),
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.help_outline,
                              title: 'Trợ giúp',
                              subtitle: 'Hướng dẫn sử dụng',
                              trailing: Icons.chevron_right,
                            ),
                            _divider(),
                            _menuItem(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Chính sách bảo mật',
                              subtitle: '',
                              trailing: Icons.chevron_right,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Edit profile
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_outlined,
                            color: ThemeConfig.teal, size: 18),
                        label: const Text('Chỉnh sửa hồ sơ',
                            style: TextStyle(color: ThemeConfig.teal)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: ThemeConfig.teal),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Logout
                      GlassCard(
                        borderRadius: 16,
                        borderColor:
                            ThemeConfig.sosRed.withValues(alpha: 0.4),
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () => _logout(context),
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout,
                                    color: ThemeConfig.sosRed, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Đăng xuất',
                                  style: TextStyle(
                                    color: ThemeConfig.sosRed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ThemeConfig.tealGradient,
            boxShadow: [
              BoxShadow(
                color: ThemeConfig.teal.withValues(alpha: 0.4),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style:
              const TextStyle(fontSize: 13, color: ThemeConfig.tealLight),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: ThemeConfig.teal.withValues(alpha: 0.15),
              ),
              child:
                  Icon(icon, color: ThemeConfig.teal, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null)
              Icon(trailing, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _switchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: ThemeConfig.teal.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: ThemeConfig.teal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
        height: 1,
        indent: 66,
        color: ThemeConfig.glassBorder);
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConfig.oceanSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('FloodSOS', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phiên bản 2.0.0',
                style: TextStyle(color: ThemeConfig.tealLight)),
            SizedBox(height: 6),
            Text('Hệ thống cảnh báo lũ lụt thông minh',
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text('UI: Calm Crisis Design',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text('Developed with ❤️ for Vietnam',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: ThemeConfig.teal)),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConfig.oceanSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc muốn đăng xuất?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: ThemeConfig.tealLight)),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.login, (route) => false);
            },
            child: const Text('Đăng xuất',
                style: TextStyle(color: ThemeConfig.sosRed)),
          ),
        ],
      ),
    );
  }
}
