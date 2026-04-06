// lib/services/api_service.dart
// Refactored: uses dio (single HTTP client) + flutter_dotenv (no hardcoded URLs/keys)
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/sos_alert_model.dart';
import '../models/flood_zone_model.dart';

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
      debugPrint("DioException in login: ${e.message} ${e.response?.statusCode} ${e.error}");
      if (e.response?.statusCode == 401) {
        return {'success': false, 'message': 'Sai tài khoản hoặc mật khẩu'};
      }
      return {'success': false, 'message': 'Lỗi kết nối Server: ${e.message}'};
    } catch (e) {
      debugPrint("Other Exception in login: $e");
      return {'success': false, 'message': 'Lỗi kết nối Server: $e'};
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
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 5),
        )
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

  // ─── WEATHER (OPEN-METEO) ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    try {
      final res = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code',
          'timezone': 'Asia/Bangkok'
        },
      );
      final current = res.data['current'] as Map<String, dynamic>;
      
      double rain = double.tryParse(current['precipitation']?.toString() ?? '0') ?? 0.0;
      double temp = double.tryParse(current['temperature_2m']?.toString() ?? '0') ?? 0.0;
      int humidity = int.tryParse(current['relative_humidity_2m']?.toString() ?? '0') ?? 0;
      int code = int.tryParse(current['weather_code']?.toString() ?? '0') ?? 0;
      
      String desc = _mapWmoToDesc(code);
      
      return {
        'temp': temp,
        'humidity': humidity,
        'rain': rain,
        'desc': desc,
        'location': 'Vị trí hiện tại',
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
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'hourly': 'temperature_2m,precipitation,weather_code',
          'timezone': 'Asia/Bangkok',
          'forecast_days': 2
        },
      );
      
      final hourly = res.data['hourly'] as Map<String, dynamic>;
      final times = hourly['time'] as List;
      final temps = hourly['temperature_2m'] as List;
      final rains = hourly['precipitation'] as List;
      final codes = hourly['weather_code'] as List;
      
      List<Map<String, dynamic>> forecast = [];
      DateTime now = DateTime.now();
      
      for (int i = 0; i < times.length; i++) {
        DateTime t = DateTime.parse(times[i].toString());
        if (t.isAfter(now) || (t.hour == now.hour && t.day == now.day)) {
          forecast.add({
            'time': '${t.hour.toString().padLeft(2, '0')}:00',
            'temp': temps[i],
            'rain': rains[i],
            'desc': _mapWmoToDesc(int.tryParse(codes[i]?.toString() ?? '0') ?? 0),
          });
          if (forecast.length == 8) break;
        }
      }
      
      return {
        'forecast': forecast,
        'alert': {'level': 'normal', 'message': 'Đã cập nhật dữ liệu từ Open-Meteo'},
      };
    } catch (_) {
      return {};
    }
  }

  static String _mapWmoToDesc(int code) {
    if (code == 0) return 'Quang mây';
    if (code == 1 || code == 2 || code == 3) return 'Có mây';
    if (code == 45 || code == 48) return 'Sương mù';
    if (code >= 51 && code <= 55) return 'Mưa phùn';
    if (code >= 61 && code <= 65) return 'Mưa rào';
    if (code >= 71 && code <= 77) return 'Tuyết rơi';
    if (code >= 80 && code <= 82) return 'Mưa lớn';
    if (code >= 95 && code <= 99) return 'Mưa dông';
    return 'Thời tiết xấu';
  }

  Future<String?> lookupNameByPhone(String p) async => null;

  /// Phân tích tuyến đường flood-aware cho vị trí SOS.
  Future<Map<String, dynamic>?> analyzeRoute(double lat, double lon) async {
    try {
      final res = await _dio.post(
        '$_backendUrl/api/sos/route',
        data: {'lat': lat, 'lon': lon},
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Lấy danh sách điểm ngập lụt (bản đồ ngập) từ backend.
  Future<List<FloodZoneModel>> getFloodZones() async {
    try {
      final res = await _dio.get(
        '$_backendUrl/api/flood-zones',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      return (res.data as List)
          .map((x) => FloodZoneModel.fromJson(x as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getFloodZones error: $e');
      return [];
    }
  }

  // ─── COMMUNITY RESCUE (Volunteer) ─────────────────────────────────────────

  Future<bool> volunteerAccept({
    required String sosId,
    required String volunteerName,
    required String volunteerPhone,
  }) async {
    try {
      final res = await _dio.post(
        '$_backendUrl/api/sos/$sosId/volunteer/accept',
        data: {'volunteerName': volunteerName, 'volunteerPhone': volunteerPhone},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> volunteerArrive({required String sosId}) async {
    try {
      final res = await _dio.post('$_backendUrl/api/sos/$sosId/volunteer/arrive');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> volunteerComplete({required String sosId}) async {
    try {
      final res = await _dio.post('$_backendUrl/api/sos/$sosId/volunteer/complete');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
