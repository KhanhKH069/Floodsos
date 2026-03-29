import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../config/theme_config.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/weather_chart.dart';

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
      context.read<WeatherProvider>().fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ThemeConfig.oceanGradient),
      child: Consumer<WeatherProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: ThemeConfig.teal),
            );
          }

          final data = provider.weatherData;
          Color riskColor = ThemeConfig.teal;
          IconData riskIcon = Icons.check_circle_outline;
          if (data['riskColor'] == 'red') {
            riskColor = ThemeConfig.sosRed;
            riskIcon = Icons.warning_amber_rounded;
          } else if (data['riskColor'] == 'orange') {
            riskColor = ThemeConfig.warnAmber;
            riskIcon = Icons.warning_outlined;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Dữ liệu ngoại tuyến (Từ bản lưu cũ)",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                // ─── Flood Risk Card ───────────────────────────────
                GlassCard(
                  borderColor: riskColor.withValues(alpha: 0.6),
                  borderRadius: 22,
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: riskColor.withValues(alpha: 0.15),
                          border: Border.all(
                              color: riskColor.withValues(alpha: 0.5),
                              width: 1.5),
                        ),
                        child: Icon(riskIcon, size: 32, color: riskColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data['floodRisk'] ?? 'An toàn',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Dựa trên lượng mưa thực tế",
                        style: TextStyle(
                            color: Colors.white54, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Temperature & Location ────────────────────────
                GlassCard(
                  borderRadius: 22,
                  child: Column(
                    children: [
                      Text(
                        data['location'] ?? '',
                        style: const TextStyle(
                            color: ThemeConfig.tealLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${data['temp']}°C",
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        data['desc'] ?? '',
                        style: const TextStyle(
                            fontSize: 18,
                            color: ThemeConfig.tealLight),
                      ),
                      const SizedBox(height: 20),
                      // Stats row
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                        children: [
                          _statBadge(
                            Icons.water_drop,
                            "${data['humidity']}%",
                            "Độ ẩm",
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: ThemeConfig.glassBorder,
                          ),
                          _statBadge(
                            Icons.cloudy_snowing,
                            "${data['rain']}mm",
                            "Lượng mưa",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Forecast & Chart ──────────────────────────────
                WeatherForecastWidget(forecast: provider.forecast24h),
                const SizedBox(height: 20),

                // ─── Refresh ───────────────────────────────────────
                TealButton(
                  label: 'Cập nhật ngay',
                  leadingIcon: const Icon(Icons.refresh,
                      color: Colors.white, size: 18),
                  onPressed: () =>
                      context.read<WeatherProvider>().fetchWeather(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statBadge(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: ThemeConfig.teal, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
