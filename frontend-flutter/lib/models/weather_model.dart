// lib/models/weather_model.dart

enum WeatherCondition { clear, cloudy, rainy, stormy, flood }

enum FloodRisk { low, medium, high, critical }

class WeatherModel {
  final String location; // Tên thành phố
  final double temperature;
  final WeatherCondition condition;
  final String description;
  final double humidity;
  final double windSpeed;
  final double rainfall; // Đổi tên từ rainVolume sang rainfall cho khớp UI
  final String iconCode;
  final List<WeatherForecast> forecast; // Thêm danh sách dự báo

  WeatherModel({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    this.rainfall = 0.0,
    required this.iconCode,
    this.forecast = const [],
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // Xử lý lượng mưa
    double rain = 0.0;
    if (json['rain'] != null) {
      if (json['rain']['1h'] != null) {
        rain = (json['rain']['1h'] as num).toDouble();
      } else if (json['rain']['3h'] != null) {
        rain = (json['rain']['3h'] as num).toDouble();
      }
    }

    // Map điều kiện thời tiết từ API sang Enum
    String main = json['weather'][0]['main'].toString().toLowerCase();
    WeatherCondition cond = WeatherCondition.cloudy;
    if (main.contains('rain') || main.contains('drizzle')) {
      cond = WeatherCondition.rainy;
    } else if (main.contains('thunder'))
      cond = WeatherCondition.stormy;
    else if (main.contains('clear')) cond = WeatherCondition.clear;

    // Tạo dữ liệu giả lập cho biểu đồ dự báo (Vì API Free không trả về Hourly)
    List<WeatherForecast> mockForecast = List.generate(24, (index) {
      return WeatherForecast(
        time: DateTime.now().add(Duration(hours: index)),
        temperature: (json['main']['temp'] as num).toDouble() + (index % 3 - 1),
        rainfall: rain > 0 ? rain + (index % 5) : 0.0,
        condition: cond,
      );
    });

    return WeatherModel(
      location: json['name'] ?? 'Không xác định',
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: cond,
      description: json['weather'][0]['description'],
      humidity: (json['main']['humidity'] as num).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble() * 3.6,
      rainfall: rain,
      iconCode: json['weather'][0]['icon'],
      forecast: mockForecast,
    );
  }
}

class WeatherForecast {
  final DateTime time;
  final double temperature;
  final double rainfall;
  final WeatherCondition condition;

  WeatherForecast({
    required this.time,
    required this.temperature,
    required this.rainfall,
    required this.condition,
  });
}

class FloodZoneModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double waterLevel;
  final FloodRisk riskLevel;
  final String description;

  FloodZoneModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.waterLevel,
    required this.riskLevel,
    required this.description,
  });

  String get riskText {
    switch (riskLevel) {
      case FloodRisk.critical:
        return 'Nguy cấp';
      case FloodRisk.high:
        return 'Cao';
      case FloodRisk.medium:
        return 'Trung bình';
      default:
        return 'An toàn';
    }
  }

  // Thêm hàm này để sửa lỗi ở socket_service.dart
  factory FloodZoneModel.fromJson(Map<String, dynamic> json) {
    return FloodZoneModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['lat'] ?? 0.0).toDouble(),
      longitude: (json['lon'] ?? 0.0).toDouble(),
      waterLevel: (json['water_level'] ?? 0.0).toDouble(),
      riskLevel: _parseRisk(json['risk_level']),
      description: json['description'] ?? '',
    );
  }

  static FloodRisk _parseRisk(String? risk) {
    switch (risk) {
      case 'critical':
        return FloodRisk.critical;
      case 'high':
        return FloodRisk.high;
      case 'medium':
        return FloodRisk.medium;
      default:
        return FloodRisk.low;
    }
  }
}
