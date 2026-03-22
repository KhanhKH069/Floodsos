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

class _AlertsListScreenState extends State<AlertsListScreen> {
  final ApiService _apiService = ApiService();
  List<SOSAlertModel> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
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

  Future<void> _deleteAlert(String id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2E3B),
        title:
            const Text("Xác nhận xóa?", style: TextStyle(color: Colors.white)),
        content: const Text("Xóa tin này khỏi hệ thống?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa ngay",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      bool success = await _apiService.deleteSOS(id);
      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Đã xóa!")));
        _fetchAlerts();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Lỗi xóa!"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _openMap(double lat, double lon) async {
    final googleMapsUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    if (await canLaunchUrl(googleMapsUrl))
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2129),
      appBar: AppBar(
        title: const Text("QUẢN LÝ CỨU HỘ",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF242836),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAlerts)
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : _alerts.isEmpty
              ? const Center(
                  child: Text("Danh sách trống",
                      style: TextStyle(color: Colors.white)))
              : RefreshIndicator(
                  onRefresh: _fetchAlerts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) =>
                        _buildAlertCard(_alerts[index]),
                  ),
                ),
    );
  }

  Widget _buildAlertCard(SOSAlertModel alert) {
    bool isCritical =
        alert.status == 'critical' || alert.waterLevel == 'Khẩn cấp';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E3B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isCritical
                ? Colors.redAccent.withValues(alpha: 0.5)
                : Colors.transparent),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCritical
                  ? const Color(0xFF4A1F1F)
                  : const Color(0xFF2E3344),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sos, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alert.name.isEmpty ? alert.phone : alert.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.delete_forever, color: Colors.redAccent),
                  onPressed: () => _deleteAlert(alert.id),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Gọi hàm này với đúng 3 tham số
                _buildInfoRow(Icons.location_on, "Vị trí",
                    "${alert.latitude}, ${alert.longitude}"),
                const SizedBox(height: 10),
                // Gọi hàm này với đúng 2 tham số
                _buildWeatherSection(alert.latitude, alert.longitude),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _buildInfoRow(Icons.water, "Mức nước",
                            alert.waterLevel ?? 'N/A')),
                    Expanded(
                        child: _buildInfoRow(Icons.groups, "Số người",
                            "${alert.peopleCount ?? '?'} người")),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10))),
            child: Row(
              children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () =>
                            _openMap(alert.latitude, alert.longitude),
                        icon: const Icon(Icons.map),
                        label: const Text("Bản đồ"))),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(alert.phone),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        icon: const Icon(Icons.call),
                        label: const Text("Gọi điện"))),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Định nghĩa hàm nhận đúng 2 tham số
  Widget _buildWeatherSection(double lat, double lon) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.getWeather(lat, lon),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.cloud, color: Colors.lightBlueAccent, size: 16),
              const SizedBox(width: 8),
              Text("${data['temp']}°C - ${data['desc']}",
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  // Định nghĩa hàm nhận đúng 3 tham số
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
      ],
    );
  }
}
