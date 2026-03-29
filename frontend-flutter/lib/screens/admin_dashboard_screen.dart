// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'alerts_list_screen.dart';
import 'admin_map_screen.dart';
import 'admin_users_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_tracking_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, String? token});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();

  int _totalSOS = 0;
  int _pendingSOS = 0;
  int _resolvedSOS = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final alerts = await _apiService.getSOSAlerts();
      setState(() {
        _totalSOS = alerts.length;
        _resolvedSOS = alerts.where((a) => a.status == 'safe').length;
        _pendingSOS = _totalSOS - _resolvedSOS;
        _statsLoading = false;
      });
    } catch (_) {
      setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E2129),
      appBar: AppBar(
        title: const Text('BẢNG ĐIỀU KHIỂN',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF242836),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới thống kê',
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Greeting ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[900]!,
                      Colors.blue[700]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.admin_panel_settings,
                          size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, ${auth.user?.name ?? 'Admin'}!',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Hệ thống quản lý FloodSOS',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Online badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                          SizedBox(width: 5),
                          Text('Online',
                              style: TextStyle(
                                  color: Colors.greenAccent, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Stats Row ───────────────────────────────────────
              const Text(
                'THỐNG KÊ THỜI GIAN THỰC',
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              _statsLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                            color: Colors.blueAccent),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'Tổng SOS',
                            count: _totalSOS,
                            icon: Icons.sos,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            label: 'Chờ cứu',
                            count: _pendingSOS,
                            icon: Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            label: 'Đã cứu',
                            count: _resolvedSOS,
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 24),

              // ─── Live Tracking Main CTA ────────────────────────────
              const Text(
                'GIÁM SÁT HIỆN TRƯỜNG',
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal[900]!,
                      Colors.teal[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.tealAccent.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminTrackingScreen()),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.gps_fixed,
                              size: 32, color: Colors.tealAccent),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theo dõi hành trình trực tiếp',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Định vị đội cứu hộ & người dân đang di tản',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.white54),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Menu Grid ───────────────────────────────────────
              const Text(
                'TÍNH NĂNG QUẢN LÝ',
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    title: 'Cảnh báo SOS',
                    subtitle: '$_pendingSOS chờ xử lý',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AlertsListScreen()),
                    ).then((_) => _loadStats()),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.map,
                    color: Colors.green,
                    title: 'Bản đồ cứu hộ',
                    subtitle: 'Trung tâm điều phối',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminMapScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.people,
                    color: Colors.blue,
                    title: 'Người gửi SOS',
                    subtitle: '$_totalSOS lượt ghi nhận',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminUsersScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.settings,
                    color: Colors.grey,
                    title: 'Cài đặt hệ thống',
                    subtitle: 'Cấu hình & thông tin',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminSettingsScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E3B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF2A2E3B),
      elevation: 3,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style:
                    TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
