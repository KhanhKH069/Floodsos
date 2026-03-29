// lib/screens/alerts_list_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/sos_alert_model.dart';

class AlertsListScreen extends StatefulWidget {
  const AlertsListScreen({super.key});

  @override
  State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<SOSAlertModel> _alerts = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _apiService.getSOSAlerts();
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<SOSAlertModel> get _pendingAlerts =>
      _alerts.where((a) => a.status != 'safe').toList();

  List<SOSAlertModel> get _resolvedAlerts =>
      _alerts.where((a) => a.status == 'safe').toList();

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _resolveAlert(SOSAlertModel alert) async {
    final confirm = await _showConfirmDialog(
      title: 'Xác nhận đã cứu hộ?',
      content: 'Đánh dấu tin SOS của ${alert.name.isEmpty ? alert.phone : alert.name} là đã được cứu thành công?',
      confirmLabel: 'Xác nhận',
      confirmColor: Colors.green,
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _apiService.resolveSOS(alert.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã xác nhận cứu hộ thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchAlerts();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Lỗi khi cập nhật trạng thái!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAlert(SOSAlertModel alert) async {
    final confirm = await _showConfirmDialog(
      title: 'Xóa tin SOS?',
      content: 'Xóa hoàn toàn tin cứu hộ này khỏi hệ thống?',
      confirmLabel: 'Xóa ngay',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _apiService.deleteSOS(alert.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Đã xóa tin SOS.')),
      );
      _fetchAlerts();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Lỗi khi xóa!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2E3B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _openMap(double lat, double lon) async {
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2129),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QUẢN LÝ CỨU HỘ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${_alerts.length} tổng | ${_pendingAlerts.length} chờ cứu',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF242836),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _fetchAlerts,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Text('Cần cứu (${_pendingAlerts.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('Đã cứu (${_resolvedAlerts.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAlertList(_pendingAlerts, isPending: true),
                _buildAlertList(_resolvedAlerts, isPending: false),
              ],
            ),
    );
  }

  Widget _buildAlertList(List<SOSAlertModel> alerts, {required bool isPending}) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.check_circle_outline : Icons.inbox_outlined,
              size: 60,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              isPending ? 'Không có yêu cầu cứu hộ nào!' : 'Chưa có ai được cứu.',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) =>
            _buildAlertCard(alerts[index], isPending: isPending),
      ),
    );
  }

  Widget _buildAlertCard(SOSAlertModel alert, {required bool isPending}) {
    final bool isCritical =
        alert.status == 'critical' || alert.waterLevel == 'Khẩn cấp';

    Color headerColor = isPending
        ? (isCritical ? const Color(0xFF4A1F1F) : const Color(0xFF2E3344))
        : const Color(0xFF1F3A2E);

    Color borderColor = isPending
        ? (isCritical
            ? Colors.redAccent.withValues(alpha: 0.5)
            : Colors.transparent)
        : Colors.green.withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E3B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          // ─── Header ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  isPending ? Icons.sos : Icons.check_circle,
                  color: isPending ? Colors.redAccent : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.name.isEmpty ? alert.phone : alert.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      if (isCritical && isPending)
                        const Text('⚠️ Khẩn cấp',
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 11)),
                    ],
                  ),
                ),
                if (isPending)
                  IconButton(
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.redAccent, size: 20),
                    tooltip: 'Xóa tin',
                    onPressed: () => _deleteAlert(alert),
                  ),
                if (!isPending)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.grey, size: 20),
                    tooltip: 'Xóa khỏi lịch sử',
                    onPressed: () => _deleteAlert(alert),
                  ),
              ],
            ),
          ),

          // ─── Body Info ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _buildWeatherSection(alert.latitude, alert.longitude),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(Icons.location_on, 'Vị trí',
                          '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(Icons.water, 'Mức nước',
                          alert.waterLevel ?? 'N/A'),
                    ),
                    Expanded(
                      child: _buildInfoRow(Icons.groups, 'Số người',
                          '${alert.peopleCount ?? '?'} người'),
                    ),
                  ],
                ),
                if (alert.message != null && alert.message!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(
                      Icons.message, 'Lời nhắn', alert.message!),
                ],
              ],
            ),
          ),

          // ─── Actions ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openMap(alert.latitude, alert.longitude),
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Bản đồ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightBlueAccent,
                      side: const BorderSide(color: Colors.lightBlueAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(alert.phone),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Gọi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: const BorderSide(color: Colors.greenAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _resolveAlert(alert),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Đã cứu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(double lat, double lon) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.getWeather(lat, lon),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!;
        final riskColor = data['riskColor'] == 'red'
            ? Colors.redAccent
            : data['riskColor'] == 'orange'
                ? Colors.orange
                : Colors.green;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud, color: Colors.lightBlueAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                '${data['temp']}°C  •  ${data['desc']}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data['floodRisk'] ?? '',
                  style: TextStyle(color: riskColor, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 15),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
