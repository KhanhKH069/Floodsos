// lib/services/api_service.dart
// Refactored: uses dio (single HTTP client) + flutter_dotenv (no hardcoded URLs/keys)
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sos_alert_model.dart';

class ApiService {
  static String get _backendUrl {
    // Đọc từ .env; nếu chạy Android emulator cần dùng 10.0.2.2
    final url = dotenv.maybeGet('BACKEND_URL');
    if (url != null && url.isNotEmpty) return url;
    // Fallback tự động theo platform
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3002';
    return 'http://127.0.0.1:3002';
  }

  static String get _owmKey =>
      dotenv.maybeGet('OWM_API_KEY') ?? '';

  // Singleton Dio instance với base config
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ));

  static String get baseUrl => _backendUrl;
  static String get openWeatherApiKey => _owmKey;

  // ─── AUTHENTICATION ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await _dio.post(
        '$_backendUrl/api/auth/login',
        data: {'username': username, 'password': password},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return {'success': false, 'message': 'Sai tài khoản hoặc mật khẩu'};
      }
      return {'success': false, 'message': 'Lỗi kết nối Server'};
    } catch (_) {
      return {'success': false, 'message': 'Lỗi kết nối Server'};
    }
  }

  Future<bool> register(
      String name, String username, String password, String phone,
      {String role = 'user'}) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // ─── CHATBOT ─────────────────────────────────────────────────────────────

  Future<String> sendChatMessage(String message) async {
    try {
      final res = await _dio.post(
        '$_backendUrl/api/chat',
        data: {'message': message},
      );
      return (res.data as Map<String, dynamic>)['reply'] ?? "Lỗi phản hồi.";
    } catch (e) {
      return "Không thể kết nối tới Server Chat.";
    }
  }

  // ─── SOS ─────────────────────────────────────────────────────────────────

  Future<bool> resolveSOS(String id) async {
    try {
      final res = await _dio.put('$_backendUrl/api/sos/$id/resolve');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetDrones() async {}

  Future<List<SOSAlertModel>> getSOSAlerts() async {
    try {
      final res = await _dio.get('$_backendUrl/api/sos');
      return (res.data as List)
          .map((x) => SOSAlertModel.fromJson(x as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteSOS(String id) async {
    try {
      await _dio.delete('$_backendUrl/api/sos/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Gửi SOS dạng text/JSON.
  Future<Map<String, dynamic>> sendTextSOS(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('$_backendUrl/api/sos/voice', data: data);
      return {'success': true, ...(res.data as Map<String, dynamic>)};
    } catch (_) {
      return {'success': false};
    }
  }

  /// Gửi SOS kèm file audio (multipart).
  Future<Map<String, dynamic>> sendVoiceSOS({
    required String deviceId,
    required double latitude,
    required double longitude,
    required int battery,
    required String audioFilePath,
    String? name,
    String? phone,
    String? waterLevel,
    String? peopleCount,
    String? message,
  }) async {
    try {
      final formData = FormData.fromMap({
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'name': name ?? '',
        'phone': phone ?? '',
        'water_level': waterLevel ?? '',
        'people_count': peopleCount ?? '1',
        'message': message ?? '',
        if (audioFilePath.isNotEmpty)
          'audio': await MultipartFile.fromFile(audioFilePath),
      });
      final res = await _dio.post('$_backendUrl/api/sos/voice', data: formData);
      return {'success': true, ...(res.data as Map<String, dynamic>)};
    } catch (_) {
      return {'success': false};
    }
  }

  // ─── WEATHER ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    try {
      final res = await _dio.get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {
          'lat': lat, 'lon': lon,
          'appid': _owmKey, 'units': 'metric', 'lang': 'vi'
        },
      );
      final data = res.data as Map<String, dynamic>;
      double rain = 0.0;
      if (data['rain'] != null && data['rain']['1h'] != null) {
        rain = double.tryParse(data['rain']['1h'].toString()) ?? 0.0;
      }
      return {
        'temp': data['main']['temp'],
        'humidity': data['main']['humidity'],
        'rain': rain,
        'desc': data['weather'][0]['description'],
        'location': data['name'],
        'floodRisk': rain > 50 ? 'Nguy cơ lũ cao' : (rain > 10 ? 'Mưa vừa' : 'An toàn'),
        'riskColor': rain > 50 ? 'red' : (rain > 10 ? 'orange' : 'green'),
      };
    } catch (_) {
      return {
        'temp': 0.0, 'humidity': 0, 'rain': 0.0,
        'desc': 'Offline', 'location': '...',
        'floodRisk': 'Chưa rõ', 'riskColor': 'grey'
      };
    }
  }

  Future<Map<String, dynamic>> getForecast(double lat, double lon) async {
    try {
      final res = await _dio.get(
        'https://api.openweathermap.org/data/2.5/forecast',
        queryParameters: {
          'lat': lat, 'lon': lon,
          'appid': _owmKey, 'units': 'metric', 'lang': 'vi'
        },
      );
      final list = (res.data as Map<String, dynamic>)['list'] as List;
      final forecast = list.take(8).map((item) {
        double rain = 0.0;
        if (item['rain'] != null && item['rain']['3h'] != null) {
          rain = double.tryParse(item['rain']['3h'].toString()) ?? 0.0;
        }
        final date = DateTime.fromMillisecondsSinceEpoch(
            (item['dt'] as int) * 1000).toLocal();
        return {
          'time': '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          'temp': item['main']['temp'],
          'rain': rain,
          'desc': item['weather'][0]['description'],
        };
      }).toList();
      return {
        'forecast': forecast,
        'alert': {'level': 'normal', 'message': 'Không có cảnh báo đặc biệt'},
      };
    } catch (_) {
      return {};
    }
  }

  Future<String?> lookupNameByPhone(String p) async => null;

  /// Phân tích tuyến đường flood-aware cho vị trí SOS.
  Future<Map<String, dynamic>?> analyzeRoute(double lat, double lon) async {
    try {
      final res = await _dio.post(
        '$_backendUrl/api/sos/route',
        data: {'lat': lat, 'lon': lon},
        options: Options(receiveTimeout: const Duration(seconds: 25)),
      );
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
