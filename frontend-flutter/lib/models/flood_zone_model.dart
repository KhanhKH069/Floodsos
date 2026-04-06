// lib/models/flood_zone_model.dart
class FloodZoneModel {
  final double lat;
  final double lon;
  final double pFlood;
  final double priorityScore;
  final String priorityLevel;
  final double affectedPopulation;

  const FloodZoneModel({
    required this.lat,
    required this.lon,
    required this.pFlood,
    required this.priorityScore,
    required this.priorityLevel,
    required this.affectedPopulation,
  });

  factory FloodZoneModel.fromJson(Map<String, dynamic> j) {
    return FloodZoneModel(
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      pFlood: (j['p_flood'] as num? ?? 0).toDouble(),
      priorityScore: (j['priority_score'] as num? ?? 0).toDouble(),
      priorityLevel: j['priority_level']?.toString() ?? 'LOW',
      affectedPopulation: (j['affected_population'] as num? ?? 0).toDouble(),
    );
  }
}
