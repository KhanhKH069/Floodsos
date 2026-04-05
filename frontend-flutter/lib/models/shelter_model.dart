class ShelterModel {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final int capacity;
  final int current;

  ShelterModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.capacity,
    required this.current,
  });

  factory ShelterModel.fromJson(Map<String, dynamic> json) {
    return ShelterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      capacity: json['capacity'] ?? 0,
      current: json['current'] ?? 0,
    );
  }
}
