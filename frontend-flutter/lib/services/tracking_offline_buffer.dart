import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/app_logger.dart';

class TrackingOfflineBuffer {
  static final TrackingOfflineBuffer _instance = TrackingOfflineBuffer._internal();
  factory TrackingOfflineBuffer() => _instance;
  TrackingOfflineBuffer._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'tracking_buffer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_tracking (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            deviceId TEXT,
            name TEXT,
            lat REAL,
            lon REAL,
            speed REAL,
            battery INTEGER,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveLocationObject(Map<String, dynamic> locationData) async {
    try {
      final db = await database;
      await db.insert(
        'offline_tracking',
        locationData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      appLogger.i("Đã lưu buffer offline tracking: 1 tọa độ");
    } catch (e) {
      appLogger.e("Lỗi lưu offline tracking: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getPendingLocations() async {
    final db = await database;
    return await db.query('offline_tracking', orderBy: 'id ASC');
  }

  Future<void> clearBuffer() async {
    final db = await database;
    await db.delete('offline_tracking');
    appLogger.i("Đã clear tracking buffer!");
  }
}
