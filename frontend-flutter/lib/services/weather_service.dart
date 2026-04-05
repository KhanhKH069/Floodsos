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

  /// Lấy danh sách vùng ngập lụt (Dữ liệu giả lập cho Huế)
  static Future<List<FloodZoneModel>> getFloodZones() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      FloodZoneModel(
        id: '1',
        name: 'Đại Nội Huế',
        latitude: 16.4690,
        longitude: 107.5760,
        waterLevel: 5.8,
        riskLevel: FloodRisk.critical,
        description: 'Mực nước dâng cao đe dọa các điểm di tích.',
      ),
      FloodZoneModel(
        id: '2',
        name: 'Phường Hương Sơ',
        latitude: 16.4950,
        longitude: 107.5600,
        waterLevel: 5.2,
        riskLevel: FloodRisk.critical,
        description: 'Khu vực thấp trũng bị ngập sâu cục bộ.',
      ),
      FloodZoneModel(
        id: '3',
        name: 'Phường Vĩ Dạ',
        latitude: 16.4735,
        longitude: 107.6072,
        waterLevel: 4.2,
        riskLevel: FloodRisk.high,
        description: 'Ngập cục bộ các nhà dân ven sông Hương.',
      ),
      FloodZoneModel(
        id: '4',
        name: 'Phường Phú Hậu',
        latitude: 16.4800,
        longitude: 107.6100,
        waterLevel: 3.5,
        riskLevel: FloodRisk.high,
        description: 'Giao thông chia cắt nhẹ tại khu tập trung.',
      ),
      FloodZoneModel(
        id: '5',
        name: 'Chợ An Cựu',
        latitude: 16.4526,
        longitude: 107.5912,
        waterLevel: 1.5,
        riskLevel: FloodRisk.medium,
        description: 'Mực nước thấp giáp các trục lộ lớn.',
      ),
      FloodZoneModel(
        id: '6',
        name: 'Ga Huế',
        latitude: 16.4590,
        longitude: 107.5780,
        waterLevel: 1.2,
        riskLevel: FloodRisk.medium,
        description: 'Nước dâng nhẹ ảnh hưởng lưu thông cục bộ.',
      ),
      FloodZoneModel(
        id: '7',
        name: 'Chùa Thiên Mụ',
        latitude: 16.4534,
        longitude: 107.5445,
        waterLevel: 0.2,
        riskLevel: FloodRisk.low,
        description: 'Tình hình hoàn toàn ổn định.',
      ),
    ];
  }

  // Hàm tạo dữ liệu thời tiết giả
  static WeatherModel _getMockWeather() {
    return WeatherModel(
      location: 'Huế (Demo)',
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
