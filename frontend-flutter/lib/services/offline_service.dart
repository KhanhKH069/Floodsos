import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sos_model.dart';

class OfflineService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'floodsos.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_sos (
            id TEXT PRIMARY KEY,
            userId TEXT,
            lat REAL,
            lng REAL,
            waterLevel TEXT,
            peopleCount INTEGER,
            createdAt INTEGER,
            status TEXT
          )
        ''');
      },
    );
  }

  // Lưu SOS khi mất mạng
  Future<void> savePendingSOS(SOSAlertModel sos) async {
    final db = await database;
    await db.insert('pending_sos', sos.toSQLiteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Đồng bộ khi có mạng
  Future<void> syncPendingSOS() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pending_sos');

    for (var map in maps) {
      try {
        // Tạo object từ SQLite data
        SOSAlertModel sos = SOSAlertModel(
          id: map['id'],
          userId: map['userId'],
          location: GeoPoint(map['lat'], map['lng']),
          waterLevel: map['waterLevel'],
          peopleCount: map['peopleCount'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
          status: SOSStatus.SENT, // Mặc định là SENT khi sync lên
        );

        // Đẩy lên Firestore
        await FirebaseFirestore.instance
            .collection('sos_alerts')
            .doc(sos.id)
            .set(sos.toMap());

        // Xóa khỏi SQLite sau khi thành công
        await db.delete('pending_sos', where: 'id = ?', whereArgs: [sos.id]);
        print("Đã đồng bộ SOS: ${sos.id}");
      } catch (e) {
        print("Lỗi đồng bộ SOS ${map['id']}: $e");
      }
    }
  }
}
