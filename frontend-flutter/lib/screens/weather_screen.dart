import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../config/theme_config.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Dùng cache nếu còn hạn (không truyền forceRefresh)
      context.read<WeatherProvider>().fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.darkBackground,
      appBar: AppBar(
        title: const Text("DỰ BÁO LŨ & THỜI TIẾT",
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: ThemeConfig.infoCyan));
          }

          final data = provider.weatherData;
          Color riskColor = ThemeConfig.safeGreen;
          IconData riskIcon = Icons.verified_user_outlined;

          if (data['riskColor'] == 'red') {
            riskColor = ThemeConfig.sosRed;
            riskIcon = Icons.warning_rounded;
          } else if (data['riskColor'] == 'orange' || data['riskColor'] == 'yellow') {
            riskColor = ThemeConfig.warningOrange;
            riskIcon = Icons.error_outline_rounded;
          }

          return RefreshIndicator(
            color: ThemeConfig.infoCyan,
            backgroundColor: ThemeConfig.darkSurface,
            onRefresh: () async {
              // Pull-to-refresh luôn force-refresh bỏ qua cache
              await context.read<WeatherProvider>().forceRefresh();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── CACHE STATUS BADGE ──────────────────────
                  _buildCacheStatusBadge(provider),
                  const SizedBox(height: 12),

                  // Thẻ Cảnh Báo Lũ (QUAN TRỌNG)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: ThemeConfig.darkSurface,
                      border: Border.all(color: riskColor.withValues(alpha: 0.5), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: riskColor.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: riskColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(riskIcon, size: 56, color: riskColor),
                        ),
                        const SizedBox(height: 20),
                        const Text("MỨC ĐỘ RỦI RO NGẬP LỤT",
                            style: TextStyle(
                                color: ThemeConfig.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        Text(
                          (data['floodRisk'] ?? 'An toàn').toString().toUpperCase(),
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: riskColor,
                              letterSpacing: 1.0),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text("Dựa trên lượng mưa và dữ liệu thủy văn khu vực.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: ThemeConfig.textSecondary.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Thông tin thời tiết
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: ThemeConfig.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on,
                                color: ThemeConfig.infoCyan, size: 20),
                            const SizedBox(width: 8),
                            Text(data['location'] ?? 'Chưa xác định',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text("${data['temp']}°C",
                            style: const TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                                height: 1.0)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                              (data['desc'] ?? '').toString().toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: ThemeConfig.infoCyan,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0)),
                        ),
                        const SizedBox(height: 32),

                        // Chi tiết
                        Row(
                          children: [
                            Expanded(
                                child: _detailItem(
                                    Icons.water_drop,
                                    "${data['humidity']}%",
                                    "Độ ẩm",
                                    ThemeConfig.infoCyan)),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.white12),
                            Expanded(
                                child: _detailItem(
                                    Icons.cloudy_snowing,
                                    "${data['rain']} mm",
                                    "Lượng mưa",
                                    Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Phần 12 giờ tới
                  if (provider.forecast24h.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text("DỰ BÁO 12 GIỜ TỚI",
                          style: TextStyle(
                              color: ThemeConfig.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0)),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: provider.forecast24h
                            .map((f) => Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: ThemeConfig.darkSurface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white12, width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(f['time'].toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white)),
                                      const SizedBox(height: 12),
                                      Icon(
                                        (f['rain'] as num) > 0
                                            ? Icons.cloudy_snowing
                                            : Icons.wb_sunny_outlined,
                                        color: (f['rain'] as num) > 0
                                            ? ThemeConfig.infoCyan
                                            : Colors.amber,
                                        size: 36,
                                      ),
                                      const SizedBox(height: 12),
                                      Text("${f['temp']}°",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                              color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(
                                        (f['rain'] as num) > 0
                                            ? "${f['rain']}mm"
                                            : "Không mưa",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: ThemeConfig.textSecondary),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Nút refresh
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.read<WeatherProvider>().forceRefresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text("CẬP NHẬT DỮ LIỆU MỚI NHẤT"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: ThemeConfig.textPrimary,
                      side: const BorderSide(color: Colors.white24, width: 1.5),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── CACHE STATUS BADGE ──────────────────────────
  Widget _buildCacheStatusBadge(WeatherProvider provider) {
    final isHit = provider.isCacheHit;
    final label = provider.cacheAgeLabel;
    if (label.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isHit
              ? const Color(0xFF30D158).withValues(alpha: 0.12)
              : ThemeConfig.infoCyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHit
                ? const Color(0xFF30D158).withValues(alpha: 0.4)
                : ThemeConfig.infoCyan.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHit ? Icons.bolt_rounded : Icons.cloud_done_rounded,
              size: 14,
              color: isHit ? const Color(0xFF30D158) : ThemeConfig.infoCyan,
            ),
            const SizedBox(width: 6),
            Text(
              isHit ? '⚡ Từ cache — $label' : '🌐 $label',
              style: TextStyle(
                fontSize: 12,
                color: isHit
                    ? const Color(0xFF30D158)
                    : ThemeConfig.infoCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(
      IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 12),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: ThemeConfig.textSecondary)),
      ],
    );
  }
}
