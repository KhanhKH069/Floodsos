import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../config/theme_config.dart';
import 'package:geolocator/geolocator.dart';

class WeatherInfoWidget extends StatefulWidget {
  const WeatherInfoWidget({super.key});

  @override
  State<WeatherInfoWidget> createState() => _WeatherInfoWidgetState();
}

class _WeatherInfoWidgetState extends State<WeatherInfoWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _timer = Timer.periodic(const Duration(hours: 3), (_) => _fetchWeather());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) context.read<WeatherProvider>().fetchWeather();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) context.read<WeatherProvider>().fetchWeather();
          return;
        }
      }
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);
      if (mounted) {
        context
            .read<WeatherProvider>()
            .fetchWeather(pos.latitude, pos.longitude);
      }
    } catch (e) {
      if (mounted) context.read<WeatherProvider>().fetchWeather();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, child) {
        final weather = provider.weatherData;
        final forecastList = provider.forecast24h;

        if (provider.isLoading &&
            weather['temp'] == 0.0 &&
            forecastList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
                child: CircularProgressIndicator(color: ThemeConfig.teal)),
          );
        }

        Map<String, dynamic>? nextForecast;
        if (forecastList.isNotEmpty) nextForecast = forecastList.first;

        // Flood risk color
        Color riskBadgeColor = ThemeConfig.teal;
        String riskLabel = weather['floodRisk'] ?? 'An toàn';
        if (weather['riskColor'] == 'red') riskBadgeColor = ThemeConfig.sosRed;
        if (weather['riskColor'] == 'orange')
          riskBadgeColor = ThemeConfig.warnAmber;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_circle,
                          color: ThemeConfig.teal, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        "Thời tiết hiện tại",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    weather['location'] ?? '',
                    style: TextStyle(
                        color: ThemeConfig.tealLight, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Temp + stats
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${weather['temp']}°C",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.0),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather['desc'] ?? '',
                          style: TextStyle(
                              color: ThemeConfig.tealLight, fontSize: 13),
                        ),
                        Text(
                          "💧 ${weather['humidity']}%  🌧 ${weather['rain']}mm",
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Flood risk badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: riskBadgeColor.withValues(alpha: 0.2),
                      border: Border.all(
                          color: riskBadgeColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      riskLabel,
                      style: TextStyle(
                          color: riskBadgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              // Forecast strip
              if (nextForecast != null) ...[
                Divider(
                    height: 20,
                    color: ThemeConfig.glassBorder),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        color: ThemeConfig.tealLight, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      "Dự báo ${nextForecast['time']}:  ${nextForecast['temp']}°C  •  ${nextForecast['rain']}mm  •  ${nextForecast['desc']}",
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
