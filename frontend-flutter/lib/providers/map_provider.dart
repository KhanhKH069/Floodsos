import 'package:flutter/material.dart';
import '../models/sos_alert_model.dart';
import '../models/flood_report_model.dart';
import '../models/drone_model.dart';
import '../models/shelter_model.dart';
import '../services/api_service.dart';

class MapProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<SOSAlertModel> alerts = [];
  List<FloodReportModel> reports = [];
  List<FloodReportModel> predictiveReports = [];
  List<DroneModel> drones = [];
  List<ShelterModel> shelters = [];

  bool isLoading = true;
  String? errorMessage;

  Future<void> loadAllData() async {
    isLoading = true;
    errorMessage = null;
    // Delay notify so it doesn't clash with initState bindings
    Future.microtask(() => notifyListeners());

    try {
      final results = await Future.wait([
        _apiService.getSOSAlerts(),
        _apiService.getFloodReports(),
        _apiService.getPredictiveFloodReports(),
        _apiService.getShelters(),
        _apiService.getDrones(),
      ]);

      alerts = (results[0] as List<SOSAlertModel>)
          .where((a) => a.latitude != 0.0 && a.longitude != 0.0)
          .toList();
      reports = results[1] as List<FloodReportModel>;
      predictiveReports = results[2] as List<FloodReportModel>;
      shelters = results[3] as List<ShelterModel>;
      drones = results[4] as List<DroneModel>;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadDrones() async {
    try {
      drones = await _apiService.getDrones();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> reloadAlertsAndReports() async {
    try {
      final results = await Future.wait([
        _apiService.getSOSAlerts(),
        _apiService.getFloodReports(),
        _apiService.getPredictiveFloodReports(),
      ]);

      alerts = (results[0] as List<SOSAlertModel>)
          .where((a) => a.latitude != 0.0 && a.longitude != 0.0)
          .toList();
      reports = results[1] as List<FloodReportModel>;
      predictiveReports = results[2] as List<FloodReportModel>;
      
      notifyListeners();
    } catch (_) {}
  }
}
