import 'package:flutter/foundation.dart';
import '../models/sos_alert_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class SOSProvider with ChangeNotifier {
  List<SOSAlertModel> _alerts = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  List<SOSAlertModel> get alerts => _alerts;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  final ApiService _apiService = ApiService();

  SOSProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    final socket = SocketService().socket;
    if (socket != null) {
      socket.on('new_sos_alert', (data) {
        try {
          final newAlert = SOSAlertModel.fromJson(data);
          addAlert(newAlert);
        } catch (e) {
          if (kDebugMode) print("Socket Parse Error: $e");
        }
      });
    }
  }

  Future<void> fetchAlerts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _alerts = await _apiService.getSOSAlerts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FIX: Đóng gói tham số vào Map để khớp với ApiService ---
  Future<bool> sendVoiceSOS({
    required String deviceId,
    required double latitude,
    required double longitude,
    required int battery,
    required String audioFilePath,
  }) async {
    _isSending = true;
    notifyListeners();

    final result = await _apiService.sendVoiceSOS(
      deviceId:      deviceId,
      latitude:      latitude,
      longitude:     longitude,
      battery:       battery,
      audioFilePath: audioFilePath,
    );

    _isSending = false;
    notifyListeners();
    return result['success'] == true;
  }

  Future<bool> sendTextSOS({
    required String deviceId,
    required double latitude,
    required double longitude,
    required int battery,
    required String message,
    required int messageIndex,
  }) async {
    _isSending = true;
    notifyListeners();

    // ApiService yêu cầu Map<String, dynamic>
    final data = {
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'battery': battery,
      'message': message,
      'messageIndex': messageIndex,
    };

    final result = await _apiService.sendTextSOS(data);

    _isSending = false;
    notifyListeners();
    return result['success'] == true;
  }

  void addAlert(SOSAlertModel alert) {
    if (!_alerts.any((element) => element.id == alert.id)) {
      _alerts.insert(0, alert);
      notifyListeners();
    }
  }
}
