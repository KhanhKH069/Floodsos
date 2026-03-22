import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WeatherProvider with ChangeNotifier {
  bool isLoading = false;

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
      'name': 'Vực Bến Thủy (Sông Lam)',
      'lat': 18.6566,
      'lon': 105.6946,
      'level': 5.8,
      'status': 'Nguy cấp',
      'riskColor': 'red'
    },
    {
      'name': 'Huyện Nam Đàn',
      'lat': 18.7027,
      'lon': 105.5015,
      'level': 4.2,
      'status': 'Cao',
      'riskColor': 'orange'
    },
    {
      'name': 'Thị xã Cửa Lò',
      'lat': 18.8023,
      'lon': 105.7121,
      'level': 1.5,
      'status': 'Trung bình',
      'riskColor': 'yellow'
    },
    {
      'name': 'Con Cuông',
      'lat': 19.0350,
      'lon': 104.9000,
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
  Future<void> fetchWeather([double? lat, double? lon]) async {
    isLoading = true;
    notifyListeners();
    try {
      final api = ApiService();
      // Gọi song song cả 2 API
      final results = await Future.wait([
        api.getWeather(lat ?? 18.67, lon ?? 105.68),
        api.getForecast(lat ?? 18.67, lon ?? 105.68)
      ]);

      _weatherData = results[0];

      // Xử lý dữ liệu dự báo
      final forecastRes = results[1];
      _forecast24h = forecastRes['forecast'] ?? [];
      _weatherAlert = forecastRes['alert'] ??
          {'level': 'normal', 'message': 'Không có cảnh báo'};
    } catch (e) {
      print("Weather Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // FIX: Thêm hàm này để MapScreen gọi không bị lỗi
  Future<void> fetchFloodZones() async {
    notifyListeners();
  }
}
