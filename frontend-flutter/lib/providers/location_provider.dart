//lib/providers/location_provider.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/nghe_an_locations.dart';

class LocationProvider with ChangeNotifier {
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  String? _error;
  bool _isSimulated = false;   // true = đang dùng vị trí giả lập Nghệ An
  String? _simulatedName;       // tên điểm giả lập để hiển thị UI

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _latitude != null && _longitude != null;
  bool get isSimulated => _isSimulated;
  String? get simulatedName => _simulatedName;

  // ─── Khóa một điểm Nghệ An cho toàn bộ session (chọn khi init) ──────────
  static final int _sessionIndex = Random().nextInt(NgheAnLocations.points.length);
  static NgheAnLocation get sessionPoint =>
      NgheAnLocations.getByIndex(_sessionIndex);

  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<void> updateLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _isSimulated = false;
      _simulatedName = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // ── Fallback: chọn ngẫu nhiên 1 trong 7 điểm Nghệ An ──────────────
      _applyNgheAnFallback(e.toString());
    }
  }

  /// Áp dụng vị trí giả lập Nghệ An (gọi khi GPS thất bại)
  void _applyNgheAnFallback(String errMsg) {
    final point = sessionPoint; // nhất quán trong session
    _latitude = point.latitude;
    _longitude = point.longitude;
    _isSimulated = true;
    _simulatedName = point.name;
    _error = errMsg;
    _isLoading = false;
    notifyListeners();
  }

  /// Cho phép màn hình gọi trực tiếp để lấy vị trí giả lập
  void useNgheAnSimulation() {
    _applyNgheAnFallback('Dùng vị trí phân tích Nghệ An');
  }

  Future<double> getDistanceToPoint(double lat, double lon) async {
    if (_latitude == null || _longitude == null) {
      await updateLocation();
    }

    if (_latitude != null && _longitude != null) {
      return Geolocator.distanceBetween(_latitude!, _longitude!, lat, lon);
    }

    return 0.0;
  }
}
