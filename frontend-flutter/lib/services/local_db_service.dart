import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbCache {
  static final LocalDbCache _instance = LocalDbCache._internal();
  factory LocalDbCache() => _instance;
  LocalDbCache._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'floodsos_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE api_cache (
            key TEXT PRIMARY KEY,
            data TEXT,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  Future<void> saveCache(String key, String jsonString) async {
    try {
      final dbClient = await db;
      await dbClient.insert(
        'api_cache',
        {
          'key': key,
          'data': jsonString,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<String?> getCache(String key) async {
    try {
      final dbClient = await db;
      final List<Map<String, dynamic>> maps = await dbClient.query(
        'api_cache',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isNotEmpty) {
        return maps.first['data'] as String;
      }
    } catch (_) {}
    return null;
  }
}
