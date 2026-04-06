import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RouteHelper {
  static const double earthRadius = 6371000; // Bán kính trái đất (mét)

  /// 1. Tính khoảng cách từ Điểm hiện tại (p) tới 1 Đoạn thẳng (v - w) trên bản đồ
  static double _distanceToSegment(LatLng p, LatLng v, LatLng w) {
    // Chuyển đổi độ sang radian
    double lat1 = v.latitude * pi / 180;
    double lon1 = v.longitude * pi / 180;
    double lat2 = w.latitude * pi / 180;
    double lon2 = w.longitude * pi / 180;
    double lat3 = p.latitude * pi / 180;
    double lon3 = p.longitude * pi / 180;

    // Chiếu phẳng (Flat-earth approximation) để xử lý khoảng cách ngắn rất nhanh
    double meanLat = (lat1 + lat2) / 2;
    double x1 = lon1 * cos(meanLat) * earthRadius;
    double y1 = lat1 * earthRadius;
    
    double x2 = lon2 * cos(meanLat) * earthRadius;
    double y2 = lat2 * earthRadius;
    
    double x3 = lon3 * cos(meanLat) * earthRadius;
    double y3 = lat3 * earthRadius;

    double dx = x2 - x1;
    double dy = y2 - y1;
    double l2 = dx * dx + dy * dy;

    if (l2 == 0) {
      return sqrt(pow(x3 - x1, 2) + pow(y3 - y1, 2)); // v và w trùng nhau
    }

    // Tìm điểm chiếu của p lên đường thẳng v-w
    double t = ((x3 - x1) * dx + (y3 - y1) * dy) / l2;
    t = max(0, min(1, t)); // Giới hạn t trong đoạn [0, 1] để nó nằm trên đoạn thẳng

    double px = x1 + t * dx;
    double py = y1 + t * dy;

    // Trả về khoảng cách từ vị trí hiện tại đến điểm hình chiếu (tính bằng mét)
    return sqrt(pow(x3 - px, 2) + pow(y3 - py, 2));
  }

  /// 2. Tìm khoảng cách ngắn nhất từ bạn tới toàn bộ tuyến đường
  static double getMinDistanceFromRoute(LatLng currentPos, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;
    if (route.length == 1) {
      return const Distance().as(LengthUnit.Meter, currentPos, route.first).toDouble();
    }

    double minDistance = double.infinity;
    for (int i = 0; i < route.length - 1; i++) {
      double dist = _distanceToSegment(currentPos, route[i], route[i + 1]);
      if (dist < minDistance) minDistance = dist;
    }
    return minDistance;
  }

  /// 3. Lấy tọa độ đường bộ từ OSRM (để vẽ men theo đường thay vì chim bay)
  static Future<List<LatLng>> getRoadRoute(LatLng start, LatLng end) async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
      final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      debugPrint('Calling OSRM: $url');
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          debugPrint('OSRM success, got ${coordinates.length} points for segment.');
          return coordinates.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        }
      } else {
        debugPrint('OSRM failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OSRM Error: $e');
    }
    return [start, end]; // Fallback về đường chim bay nếu lỗi mạng hoặc OSRM sập
  }
}
