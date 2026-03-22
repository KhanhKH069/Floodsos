class DroneModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String status;
  final int battery;

  DroneModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.battery,
  });

  factory DroneModel.fromJson(Map<String, dynamic> json) {
    return DroneModel(
      id: json['id'],
      name: json['name'],
      latitude: (json['lat'] ?? 0).toDouble(),
      longitude: (json['lon'] ?? 0).toDouble(),
      status: json['status'],
      battery: json['battery'],
    );
  }
}
