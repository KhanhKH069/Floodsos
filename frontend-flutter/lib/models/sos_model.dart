// lib/models/sos_model.dart

// Enum trạng thái SOS
enum SOSStatus { SENT, RECEIVED, DISPATCHING, EN_ROUTE, COMPLETED, CANCELLED }

// Enum trạng thái đội cứu hộ
enum TeamStatus { AVAILABLE, BUSY, OFFLINE }

// Class lịch sử trạng thái
class StatusHistory {
  final SOSStatus status;
  final DateTime timestamp;
  final String? note;

  StatusHistory({required this.status, required this.timestamp, this.note});

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      status: SOSStatus.values.firstWhere((e) => e.name == map['status']),
      timestamp: DateTime.parse(map['timestamp']),
      note: map['note'],
    );
  }
}

// Model chính SOS Alert
class SOSAlertModel {
  final String id;
  final String userId;
  final dynamic location; // Dùng dynamic thay vì GeoPoint
  final String waterLevel;
  final int peopleCount;
  final bool hasChildren;
  final bool hasElderly;
  SOSStatus status;
  String? assignedTeamId;
  DateTime createdAt;
  DateTime? dispatchedAt;
  DateTime? completedAt;
  List<StatusHistory> history;

  SOSAlertModel({
    required this.id,
    required this.userId,
    required this.location,
    required this.waterLevel,
    required this.peopleCount,
    this.hasChildren = false,
    this.hasElderly = false,
    this.status = SOSStatus.SENT,
    this.assignedTeamId,
    required this.createdAt,
    this.dispatchedAt,
    this.completedAt,
    this.history = const [],
  });

  // Helper: Lấy latitude từ location (cross-platform)
  double get latitude {
    if (location is Map) {
      return location['latitude'] ?? 0.0;
    }
    // GeoPoint có property .latitude
    return location?.latitude ?? 0.0;
  }

  // Helper: Lấy longitude từ location (cross-platform)
  double get longitude {
    if (location is Map) {
      return location['longitude'] ?? 0.0;
    }
    return location?.longitude ?? 0.0;
  }

  // Convert từ Firestore Document
  factory SOSAlertModel.fromFirestore(dynamic doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SOSAlertModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      location: data['location'], // Để nguyên type gốc
      waterLevel: data['waterLevel'] ?? 'Thấp',
      peopleCount: data['peopleCount'] ?? 1,
      hasChildren: data['hasChildren'] ?? false,
      hasElderly: data['hasElderly'] ?? false,
      status: SOSStatus.values.firstWhere(
          (e) => e.name == (data['status'] ?? 'SENT'),
          orElse: () => SOSStatus.SENT),
      assignedTeamId: data['assignedTeamId'],
      createdAt: _parseTimestamp(data['createdAt']),
      dispatchedAt: data['dispatchedAt'] != null
          ? _parseTimestamp(data['dispatchedAt'])
          : null,
      history: (data['history'] as List<dynamic>?)
              ?.map((e) => StatusHistory.fromMap(e))
              .toList() ??
          [],
    );
  }

  // Helper: Parse Timestamp cross-platform
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    // Firestore Timestamp có method .toDate()
    try {
      return timestamp.toDate();
    } catch (e) {
      return DateTime.now();
    }
  }

  // Convert sang Map (cho Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'location': location,
      'waterLevel': waterLevel,
      'peopleCount': peopleCount,
      'hasChildren': hasChildren,
      'hasElderly': hasElderly,
      'status': status.name,
      'assignedTeamId': assignedTeamId,
      'createdAt': _toTimestamp(createdAt),
      'history': history.map((e) => e.toMap()).toList(),
    };
  }

  // Helper: Convert DateTime sang Timestamp
  static dynamic _toTimestamp(DateTime date) {
    try {
      // Nếu có Firestore, dùng Timestamp.fromDate()
      // Nếu không (Desktop), return DateTime
      return date;
    } catch (e) {
      return date;
    }
  }

  // Helper cho SQLite
  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'userId': userId,
      'lat': latitude,
      'lng': longitude,
      'waterLevel': waterLevel,
      'peopleCount': peopleCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status.name,
    };
  }
}

// Model Đội cứu hộ
class RescueTeamModel {
  final String id;
  final String name;
  TeamStatus status;
  dynamic currentLocation; // Dùng dynamic thay vì GeoPoint
  String? assignedSOSId;

  RescueTeamModel({
    required this.id,
    required this.name,
    this.status = TeamStatus.AVAILABLE,
    this.currentLocation,
    this.assignedSOSId,
  });
}
