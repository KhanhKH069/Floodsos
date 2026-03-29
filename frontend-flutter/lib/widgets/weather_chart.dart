import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme_config.dart';
import 'glass_widgets.dart';

class WeatherForecastWidget extends StatelessWidget {
  final List<dynamic> forecast;

  const WeatherForecastWidget({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Timeline 24h ───────────────────────────────
        GlassCard(
          borderRadius: 22,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Dự báo 24 giờ tới",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: forecast.length,
                  itemBuilder: (context, index) {
                    final item = forecast[index];
                    final double rain = (item['rain'] ?? 0.0).toDouble();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['time'] ?? '',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            rain > 0 ? Icons.water_drop : Icons.cloud_outlined,
                            color: rain > 10
                                ? ThemeConfig.warnAmber
                                : ThemeConfig.tealLight,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${item['temp']}°",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Biểu đồ lượng mưa ───────────────────────────
        GlassCard(
          borderRadius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Lượng mưa (mm)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxRain(forecast),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey.withValues(alpha: 0.9),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY} mm\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: <TextSpan>[
                              TextSpan(
                                text: forecast[group.x.toInt()]['time'],
                                style: const TextStyle(
                                    color: ThemeConfig.tealLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final int index = value.toInt();
                            if (index < 0 || index >= forecast.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                forecast[index]['time'].toString(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: forecast.asMap().entries.map((e) {
                      final int index = e.key;
                      final double rain = (e.value['rain'] ?? 0.0).toDouble();
                      Color barColor = ThemeConfig.tealLight;
                      if (rain > 50) {
                        barColor = ThemeConfig.sosRed;
                      } else if (rain > 10) {
                        barColor = ThemeConfig.warnAmber;
                      }
                      
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: rain,
                            color: barColor,
                            width: 14,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: _getMaxRain(forecast),
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getMaxRain(List<dynamic> forecast) {
    double max = 20.0; // Default min max
    for (var item in forecast) {
      final double r = (item['rain'] ?? 0.0).toDouble();
      if (r > max) max = r;
    }
    // Round up to nearest 10
    return ((max / 10).ceil() * 10).toDouble() + 5;
  }
}
