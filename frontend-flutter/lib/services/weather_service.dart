import 'dart:async';
import '../models/weather_model.dart';

class WeatherService {
  // Chế độ Offline: Không cần API Key thật
  // static const String _apiKey = 'YOUR_API_KEY';

  /// Lấy thời tiết (Chế độ giả lập - Mock Data)
  static Future<WeatherModel> getWeather(double lat, double lon) async {
    // Giả lập thời gian chờ mạng (0.5 giây) cho giống thật
    await Future.delayed(const Duration(milliseconds: 500));

    // Trả về dữ liệu giả luôn, không gọi API để tránh lỗi 401
    return _getMockWeather();
  }

  /// Lấy danh sách vùng ngập lụt (Dữ liệu giả lập cho Nghệ An)
  static Future<List<FloodZoneModel>> getFloodZones() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      FloodZoneModel(
        id: '1',
        name: 'Vực Bến Thủy (Sông Lam)',
        latitude: 18.6566,
        longitude: 105.6946,
        waterLevel: 5.8,
        riskLevel: FloodRisk.critical,
        description: 'Mực nước sông Lam dâng cao trên báo động 3.',
      ),
      FloodZoneModel(
        id: '2',
        name: 'Huyện Nam Đàn',
        latitude: 18.7027,
        longitude: 105.5015,
        waterLevel: 4.2,
        riskLevel: FloodRisk.high,
        description: 'Ngập cục bộ các xã vùng trũng ven sông.',
      ),
      FloodZoneModel(
        id: '3',
        name: 'Thị xã Cửa Lò',
        latitude: 18.8023,
        longitude: 105.7121,
        waterLevel: 1.5,
        riskLevel: FloodRisk.medium,
        description: 'Ngập nhẹ một số tuyến đường ven biển do triều cường.',
      ),
      FloodZoneModel(
        id: '4',
        name: 'Con Cuông (Vùng núi)',
        latitude: 19.0350,
        longitude: 104.9000,
        waterLevel: 0.2,
        riskLevel: FloodRisk.low,
        description: 'Tình hình ổn định, có mưa nhỏ.',
      ),
    ];
  }

  // Hàm tạo dữ liệu thời tiết giả
  static WeatherModel _getMockWeather() {
    return WeatherModel(
      location: 'Nghệ An (Demo)',
      temperature: 26.5,
      condition: WeatherCondition.rainy,
      description: 'Mưa rào nhẹ',
      humidity: 82,
      windSpeed: 12,
      rainfall: 15.0,
      iconCode: '10d', // Icon mưa
      forecast: List.generate(24, (index) {
        // Tạo dự báo giả cho 24h tới
        return WeatherForecast(
          time: DateTime.now().add(Duration(hours: index)),
          temperature: 26.0 + (index % 3), // Nhiệt độ dao động nhẹ
          rainfall: index < 5 ? 10.0 : 0.0, // Mưa trong 5 tiếng đầu
          condition:
              index < 5 ? WeatherCondition.rainy : WeatherCondition.cloudy,
        );
      }),
    );
  }
}
