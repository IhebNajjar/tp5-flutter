import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalQueueService {
  Database? _database;
  static const String tableName = 'local_clients';
  static const String _webStorageKey = 'tp5_local_clients_v1';
  final bool inMemory;
  final List<Map<String, dynamic>> _webFallback = [];
  bool _webLoaded = false;

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

  Future<void> _ensureWebLoaded() async {
    if (!kIsWeb || inMemory || _webLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_webStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _webFallback.clear();
          for (var item in decoded) {
            if (item is Map) {
              _webFallback.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }
      _webLoaded = true;
    } catch (e) {
      debugPrint('Failed to load web clients from storage: $e');
    }
  }

  Future<void> _persistWeb() async {
    if (!kIsWeb || inMemory) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_webFallback);
      await prefs.setString(_webStorageKey, encoded);
    } catch (e) {
      debugPrint('Failed to persist web clients: $e');
    }
  }

  Future<void> insertClientLocally(Map<String, dynamic> client) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webFallback.removeWhere((c) => c['id'] == client['id']);
      _webFallback.add(Map<String, dynamic>.from(client));
      await _persistWeb();
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
      await _persistWeb();
      return;
    }
    final db = await database;
    await db?.delete(tableName);
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    if (kIsWeb) {
      await _ensureWebLoaded();
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
      await _ensureWebLoaded();
      return _webFallback.where((c) => c['is_synced'] == 0).toList();
    }
    final db = await database;
    return await db?.query(tableName, where: 'is_synced = ?', whereArgs: [0]) ?? [];
  }

  Future<void> markClientAsSynced(String id) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webFallback.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _webFallback[index]['is_synced'] = 1;
        await _persistWeb();
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
      await _ensureWebLoaded();
      _webFallback.removeWhere((c) => c['id'] == id);
      await _persistWeb();
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
