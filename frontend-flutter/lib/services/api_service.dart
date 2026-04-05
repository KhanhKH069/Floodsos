// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/sos_alert_model.dart';
import '../models/drone_model.dart';
import '../models/flood_report_model.dart';
import '../models/shelter_model.dart';
import '../services/local_db_service.dart';

class ApiService {
  static const String openWeatherApiKey = "2e65127e909e178d0af311a81f39948c";

  static String get baseUrl {
    if (kIsWeb ||
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return 'http://192.168.1.14:3002';
    }
    if (Platform.isAndroid) return 'http://192.168.1.14:3002';
    return 'http://192.168.1.14:3002';
  }

  // --- AUTHENTICATION REMOVED ---

  // --- CHATBOT (FIX LỖI MẤT HÀM NÀY) ---

  Future<String> sendChatMessage(String message) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data['reply'] ?? "Lỗi phản hồi.";
      }
    } catch (e) {
      debugPrint("Lỗi Chat: $e");
    }
    return "Không thể kết nối tới Server Chat.";
  }

  // --- SOS & DRONE ---

  Future<List<DroneModel>> getDrones() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/drones'));
      if (response.statusCode == 200) {
        LocalDbCache().saveCache('drones', response.body);
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => DroneModel.fromJson(item)).toList();
      }
      throw Exception('Lỗi tãi Drone: Mã lỗi ${response.statusCode}');
    } catch (e) {
      final cached = await LocalDbCache().getCache('drones');
      if (cached != null) {
        final List<dynamic> data = json.decode(cached);
        return data.map((item) => DroneModel.fromJson(item)).toList();
      }
      throw Exception('Không thể tải Drones: Mất kết nối');
    }
  }

  Future<List<SOSAlertModel>> getSOSAlerts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/sos'));
      if (res.statusCode == 200) {
        LocalDbCache().saveCache('sos_alerts', res.body);
        return (json.decode(res.body) as List)
            .map((x) => SOSAlertModel.fromJson(x))
            .toList();
      }
      throw Exception('Lỗi API SOS');
    } catch (_) {
      final cached = await LocalDbCache().getCache('sos_alerts');
      if (cached != null) {
        return (json.decode(cached) as List)
            .map((x) => SOSAlertModel.fromJson(x))
            .toList();
      }
      throw Exception('Mất kết nối API SOS');
    }
  }

  Future<bool> deleteSOS(String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/api/sos/$id'));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendTextSOS(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/sos/voice'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendVoiceSOS(Map<String, String> fields, String filePath) async {
    try {
      var req =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/api/sos/voice'));
      req.fields.addAll(fields);
      if (filePath.isNotEmpty) {
        req.files.add(await http.MultipartFile.fromPath('audio', filePath));
      }
      var res = await req.send();
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- FLOOD REPORTS ---
  Future<List<FloodReportModel>> getFloodReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/reports'));
      if (res.statusCode == 200) {
        LocalDbCache().saveCache('reports', res.body);
        return (json.decode(res.body) as List)
            .map((x) => FloodReportModel.fromJson(x))
            .toList();
      }
      throw Exception('Lỗi tải báo ngập');
    } catch (_) {
      final cached = await LocalDbCache().getCache('reports');
      if (cached != null) {
        return (json.decode(cached) as List)
            .map((x) => FloodReportModel.fromJson(x))
            .toList();
      }
      throw Exception('Mất kết nối dữ liệu báo ngập');
    }
  }

  Future<List<FloodReportModel>> getPredictiveFloodReports() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/predict_flood'));
      if (res.statusCode == 200) {
        LocalDbCache().saveCache('predictive_reports', res.body);
        return (json.decode(res.body) as List)
            .map((x) => FloodReportModel.fromJson(x))
            .toList();
      }
      throw Exception('Lỗi tải dự báo');
    } catch (_) {
      final cached = await LocalDbCache().getCache('predictive_reports');
      if (cached != null) {
        return (json.decode(cached) as List)
            .map((x) => FloodReportModel.fromJson(x))
            .toList();
      }
      throw Exception('Mất kết nối dự báo');
    }
  }

  Future<bool> sendFloodReport(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/reports'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- SHELTERS ---
  Future<List<ShelterModel>> getShelters() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/shelters'));
      if (res.statusCode == 200) {
        LocalDbCache().saveCache('shelters', res.body);
        return (json.decode(res.body) as List)
            .map((x) => ShelterModel.fromJson(x))
            .toList();
      }
      throw Exception('Lỗi API Shelters');
    } catch (_) {
      final cached = await LocalDbCache().getCache('shelters');
      if (cached != null) {
        return (json.decode(cached) as List)
            .map((x) => ShelterModel.fromJson(x))
            .toList();
      }
      throw Exception('Mất kết nối Trạm cứu hộ');
    }
  }

  // --- UTILS ---
  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    try {
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$openWeatherApiKey&units=metric&lang=vi'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        // Tính toán floodRisk dựa vào lượng mưa hoặc điều kiện thời tiết
        String floodRisk = 'An toàn';
        String riskColor = 'green';
        double rainVolume = 0.0;

        if (data['rain'] != null && data['rain']['1h'] != null) {
          rainVolume = (data['rain']['1h'] as num).toDouble();
          if (rainVolume > 50) {
            floodRisk = 'Nguy hiểm';
            riskColor = 'red';
          } else if (rainVolume > 15) {
            floodRisk = 'Nguy cơ cao';
            riskColor = 'orange';
          } else {
            floodRisk = 'Có thể ngập nhẹ';
            riskColor = 'yellow';
          }
        } else if (data['weather'] != null &&
            (data['weather'][0]['main'] == 'Rain' ||
                data['weather'][0]['main'] == 'Thunderstorm')) {
          floodRisk = 'Cảnh báo mưa lớn';
          riskColor = 'orange';
        }

        return {
          'temp': data['main']['temp'].round(),
          'humidity': data['main']['humidity'],
          'rain': rainVolume,
          'desc': data['weather'][0]['description'],
          'location': data['name'],
          'floodRisk': floodRisk,
          'riskColor': riskColor
        };
      }
    } catch (e) {
      debugPrint("OpenWeather API Error: $e");
    }
    return {'temp': 0, 'desc': 'Offline', 'floodRisk': 'Không rõ', 'riskColor': 'grey'};
  }

  Future<Map<String, dynamic>> getForecast(double lat, double lon) async {
    try {
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$openWeatherApiKey&units=metric&lang=vi'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        List<dynamic> list = data['list'] ?? [];
        List<Map<String, dynamic>> forecast = [];
        
        // Lấy 4 mốc thời gian tiếp theo (12 tiếng tới)
        for (int i = 0; i < 4 && i < list.length; i++) {
          final item = list[i];
          final dtStr = item['dt_txt'] as String; // OpenWeatherMap trả về giờ UTC "2023-10-10 12:00:00"
          
          // Chuyển UTC sang độ lệch múi giờ Local (Việt Nam +7)
          final DateTime utcTime = DateTime.parse('${dtStr.replaceFirst(' ', 'T')}Z');
          final DateTime localTime = utcTime.toLocal();
          final time = "${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";
          
          forecast.add({
            'time': time,
            'temp': item['main']['temp'].round(),
            'desc': item['weather'][0]['description'],
            'rain': (item['rain'] != null && item['rain']['3h'] != null) 
                    ? (item['rain']['3h'] as num).toDouble() : 0.0,
          });
        }
        
        return {
          'forecast': forecast,
          'alert': {'level': 'normal', 'message': 'Cập nhật dự báo thành công'}
        };
      }
    } catch(e) {
      debugPrint("Forecast API Error: $e");
    }
    return {
      'forecast': [],
      'alert': {'level': 'normal', 'message': 'Không có dữ liệu cảnh báo mới'}
    };
  }
  Future<String?> lookupNameByPhone(String p) async => null;
}
