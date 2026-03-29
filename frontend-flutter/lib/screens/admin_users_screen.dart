// lib/screens/admin_users_screen.dart
// Màn hình tổng hợp người gửi SOS — aggregated từ alert history
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ApiService _apiService = ApiService();
  List<_CallerSummary> _callers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCallers();
  }

  Future<void> _loadCallers() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _apiService.getSOSAlerts();
      final Map<String, _CallerSummary> map = {};

      for (final a in alerts) {
        final key = a.phone.isEmpty ? 'Ẩn danh_${a.id}' : a.phone;
        if (map.containsKey(key)) {
          map[key]!.sosCount++;
          if (a.status != 'safe') map[key]!.activeSosCount++;
          if (a.createdAt != null &&
              (map[key]!.lastSOS == null ||
                  a.createdAt!.isAfter(map[key]!.lastSOS!))) {
            map[key]!.lastSOS = a.createdAt;
          }
        } else {
          map[key] = _CallerSummary(
            name: a.name.isEmpty ? 'Người dùng ẩn danh' : a.name,
            phone: a.phone,
            sosCount: 1,
            activeSosCount: a.status != 'safe' ? 1 : 0,
            lastSOS: a.createdAt,
            lastStatus: a.status,
          );
        }
      }

      setState(() {
        _callers = map.values.toList()
          ..sort((a, b) => (b.lastSOS ?? DateTime(0))
              .compareTo(a.lastSOS ?? DateTime(0)));
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<_CallerSummary> get _filtered {
    if (_searchQuery.isEmpty) return _callers;
    final q = _searchQuery.toLowerCase();
    return _callers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.phone.contains(q))
        .toList();
  }

  Future<void> _call(String phone) async {
    final url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2129),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NGƯỜI GỬI SOS',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${_callers.length} số điện thoại duy nhất',
                style:
                    const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF242836),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCallers),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2A2E3B),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Chưa có dữ liệu'
                            : 'Không tìm thấy kết quả',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 15),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCallers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _buildCard(_filtered[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(_CallerSummary caller) {
    final hasActive = caller.activeSosCount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E3B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: hasActive
                ? Colors.redAccent.withValues(alpha: 0.4)
                : Colors.white12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              hasActive ? Colors.red[900] : Colors.blueGrey[800],
          child: Text(
            caller.name.isNotEmpty ? caller.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(caller.name,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(caller.phone.isEmpty ? 'Không có SĐT' : caller.phone,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                _badge(
                    '${caller.sosCount} SOS tổng', Colors.blueGrey),
                const SizedBox(width: 6),
                if (hasActive)
                  _badge('${caller.activeSosCount} chờ cứu',
                      Colors.redAccent),
                if (!hasActive)
                  _badge('Đã an toàn', Colors.green),
              ],
            ),
            if (caller.lastSOS != null) ...[
              const SizedBox(height: 3),
              Text(_timeAgo(caller.lastSOS!),
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 11)),
            ],
          ],
        ),
        trailing: caller.phone.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.call, color: Colors.greenAccent),
                onPressed: () => _call(caller.phone),
              )
            : null,
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child:
          Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return 'Lần cuối: ${diff.inMinutes}p trước';
    if (diff.inHours < 24) return 'Lần cuối: ${diff.inHours}h trước';
    return 'Lần cuối: ${time.day}/${time.month}/${time.year}';
  }
}

class _CallerSummary {
  final String name;
  final String phone;
  int sosCount;
  int activeSosCount;
  DateTime? lastSOS;
  final String lastStatus;

  _CallerSummary({
    required this.name,
    required this.phone,
    required this.sosCount,
    required this.activeSosCount,
    required this.lastSOS,
    required this.lastStatus,
  });
}
