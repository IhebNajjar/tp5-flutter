import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalQueueService {
  Database? _database;
  static const String tableName = 'local_clients';
  final bool inMemory;
  final List<Map<String, dynamic>> _webFallback = [];

  LocalQueueService({this.inMemory = false});

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database;
  }

  Future<Database?> _initDB() async {
    if (kIsWeb) return null;
    if (inMemory) {
      return await openDatabase(
        ':memory:',
        version: 1,
        onCreate: _onCreate,
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'waiting_room.db');
      return openDatabase(path, version: 1, onCreate: _onCreate);
    }
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lat REAL,
        lng REAL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> insertClientLocally(Map<String, dynamic> client) async {
    if (kIsWeb) {
      _webFallback.removeWhere((c) => c['id'] == client['id']);
      _webFallback.add(Map<String, dynamic>.from(client));
      return;
    }
    final db = await database;
    await db?.insert(
      tableName,
      client,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clear() async {
    if (kIsWeb) {
      _webFallback.clear();
      return;
    }
    final db = await database;
    await db?.delete(tableName);
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    if (kIsWeb) {
      final list = List<Map<String, dynamic>>.from(_webFallback);
      list.sort((a, b) =>
          (a['created_at']?.toString() ?? '')
              .compareTo(b['created_at']?.toString() ?? ''));
      return list;
    }
    final db = await database;
    return await db?.query(tableName, orderBy: 'created_at ASC') ?? [];
  }

  Future<List<Map<String, dynamic>>> getUnsyncedClients() async {
    if (kIsWeb) {
      return _webFallback.where((c) => c['is_synced'] == 0).toList();
    }
    final db = await database;
    return await db?.query(tableName, where: 'is_synced = ?', whereArgs: [0]) ?? [];
  }

  Future<void> markClientAsSynced(String id) async {
    if (kIsWeb) {
      final index = _webFallback.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _webFallback[index]['is_synced'] = 1;
      }
      return;
    }
    final db = await database;
    await db?.update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeClientLocally(String id) async {
    if (kIsWeb) {
      _webFallback.removeWhere((c) => c['id'] == id);
      return;
    }
    final db = await database;
    await db?.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
