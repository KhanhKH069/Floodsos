class FloodReportModel {
  final String id;
  final double lat;
  final double lon;
  final String severity; // 'low', 'medium', 'critical'
  final String description;
  final DateTime createdAt;

  FloodReportModel({
    required this.id,
    required this.lat,
    required this.lon,
    required this.severity,
    required this.description,
    required this.createdAt,
  });

  factory FloodReportModel.fromJson(Map<String, dynamic> json) {
    return FloodReportModel(
      id: json['_id'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'low',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'severity': severity,
      'description': description,
    };
  }
}
