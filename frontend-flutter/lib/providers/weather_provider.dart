import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WeatherProvider with ChangeNotifier {
  bool isLoading = false;

  // ─── CACHE ENGINE ───────────────────────────
  Map<String, dynamic>? _cachedWeatherData;
  Map<String, dynamic>? _cachedForecast;
  DateTime? _cacheTimestamp;
  static const int _cacheValidMinutes = 10; // TTL: 10 phút

  bool get isCacheHit {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!).inMinutes <
        _cacheValidMinutes;
  }

  String get cacheAgeLabel {
    if (_cacheTimestamp == null) return '';
    final diff = DateTime.now().difference(_cacheTimestamp!);
    if (diff.inSeconds < 60) return 'Vừa cập nhật';
    return 'Cập nhật ${diff.inMinutes} phút trước';
  }
  // ────────────────────────────────────────────

  // Dữ liệu thời tiết dạng Map
  Map<String, dynamic> _weatherData = {
    'temp': 0.0,
    'humidity': 0,
    'rain': 0.0,
    'desc': 'Đang tải...',
    'location': '...',
    'floodRisk': 'Đang cập nhật...',
    'riskColor': 'grey'
  };

  // MỚI: Dữ liệu dự báo & cảnh báo
  List<dynamic> _forecast24h = [];
  Map<String, dynamic> _weatherAlert = {
    'level': 'normal',
    'message': 'Đang tải dự báo...'
  };

  // Dữ liệu vùng lũ dạng List Map
  final List<Map<String, dynamic>> _floodZones = [
    {
      'name': 'Đại Nội Huế',
      'lat': 16.4690,
      'lon': 107.5760,
      'level': 5.8,
      'status': 'Nguy cấp',
      'riskColor': 'red'
    },
    {
      'name': 'Phường Hương Sơ',
      'lat': 16.4950,
      'lon': 107.5600,
      'level': 5.2,
      'status': 'Nguy cấp',
      'riskColor': 'red'
    },
    {
      'name': 'Phường Vĩ Dạ',
      'lat': 16.4735,
      'lon': 107.6072,
      'level': 4.2,
      'status': 'Cao',
      'riskColor': 'orange'
    },
    {
      'name': 'Phường Phú Hậu',
      'lat': 16.4800,
      'lon': 107.6100,
      'level': 3.5,
      'status': 'Cao',
      'riskColor': 'orange'
    },
    {
      'name': 'Chợ An Cựu',
      'lat': 16.4526,
      'lon': 107.5912,
      'level': 1.5,
      'status': 'Trung bình',
      'riskColor': 'yellow'
    },
    {
      'name': 'Ga Huế',
      'lat': 16.4590,
      'lon': 107.5780,
      'level': 1.2,
      'status': 'Trung bình',
      'riskColor': 'yellow'
    },
    {
      'name': 'Chùa Thiên Mụ',
      'lat': 16.4534,
      'lon': 107.5445,
      'level': 0.2,
      'status': 'An toàn',
      'riskColor': 'green'
    },
  ];

  // Getters cho màn hình sử dụng
  Map<String, dynamic> get weatherData => _weatherData;
  Map<String, dynamic> get weather => _weatherData;
  List<dynamic> get forecast24h => _forecast24h;
  Map<String, dynamic> get weatherAlert => _weatherAlert;
  List<Map<String, dynamic>> get floodZones => _floodZones;

  // FIX: Cho phép gọi không cần tham số (optional parameters)
  Future<void> fetchWeather([double? lat, double? lon, bool forceRefresh = false]) async {
    // ── CHECK CACHE: Nếu cache còn hạn và không force-refresh, trả cache ngay ──
    if (!forceRefresh && isCacheHit) {
      debugPrint("⚡ WeatherCache HIT — trả dữ liệu tức thì ($cacheAgeLabel)");
      if (_cachedWeatherData != null) {
        _weatherData = _cachedWeatherData!;
      }
      if (_cachedForecast != null) {
        final forecastRes = _cachedForecast!;
        _forecast24h = forecastRes['forecast'] ?? [];
        _weatherAlert = forecastRes['alert'] ?? {'level': 'normal', 'message': 'Không có cảnh báo'};
      }
      notifyListeners();
      return;
    }

    // ── CACHE MISS hoặc FORCE REFRESH: Gọi API thật ──
    isLoading = true;
    notifyListeners();
    try {
      final api = ApiService();
      // Gọi song song cả 2 API
      final results = await Future.wait([
        api.getWeather(lat ?? 16.4637, lon ?? 107.5909),
        api.getForecast(lat ?? 16.4637, lon ?? 107.5909)
      ]);

      _weatherData = results[0];
      final forecastRes = results[1];

      // ── LƯU VÀO CACHE ──
      _cachedWeatherData = Map<String, dynamic>.from(_weatherData);
      _cachedForecast = Map<String, dynamic>.from(forecastRes);
      _cacheTimestamp = DateTime.now();
      debugPrint("✅ WeatherCache SAVED — hết hạn sau $_cacheValidMinutes phút");

      // Xử lý dữ liệu dự báo
      _forecast24h = forecastRes['forecast'] ?? [];
      _weatherAlert = forecastRes['alert'] ??
          {'level': 'normal', 'message': 'Không có cảnh báo'};
    } catch (e) {
      debugPrint("Weather Error: $e");
      // Fallback: dùng cache cũ dù đã hết hạn nếu có
      if (_cachedWeatherData != null) {
        _weatherData = _cachedWeatherData!;
        debugPrint("⚠️ API lỗi — dùng cache cũ làm fallback");
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Force refresh (bỏ qua cache)
  Future<void> forceRefresh([double? lat, double? lon]) async {
    return fetchWeather(lat, lon, true);
  }

  // FIX: Thêm hàm này để MapScreen gọi không bị lỗi
  Future<void> fetchFloodZones() async {
    notifyListeners();
  }
}
