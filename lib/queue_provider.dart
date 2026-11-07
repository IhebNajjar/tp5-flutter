import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'geolocation_service.dart';
import 'local_queue_service.dart';

class QueueProvider extends ChangeNotifier {
  final SupabaseClient? _supabase;
  final LocalQueueService _localDb;
  final GeolocationService _geoService;
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => List.unmodifiable(_clients);

  QueueProvider({
    SupabaseClient? supabase,
    LocalQueueService? localDb,
    GeolocationService? geoService,
  })  : _supabase = supabase ?? _getSupabaseClientSafely(),
        _localDb = localDb ?? LocalQueueService(inMemory: _isTestMode),
        _geoService = geoService ?? GeolocationService() {
    initialize();
  }

  @visibleForTesting
  QueueProvider.forTesting(
    SupabaseClient supabase, {
    LocalQueueService? localDb,
    GeolocationService? geoService,
  })  : _supabase = supabase,
        _localDb = localDb ?? LocalQueueService(inMemory: true),
        _geoService = geoService ?? GeolocationService(),
        super() {
    initialize();
  }

  static bool get _isTestMode {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient? _getSupabaseClientSafely() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    await _loadQueue();
  }

  Future<void> _loadQueue() async {
    // 1. Load from local DB immediately (offline support)
    try {
      final localList = await _localDb.getClients();
      final localMap = {for (var c in localList) c['id']: c};
      for (var c in _clients) {
        localMap[c['id']] = c;
      }
      _clients = localMap.values.toList();
      _sortClients();
      notifyListeners();
    } catch (e) {
      debugPrint('Local queue load failed: $e');
    }

    // 2. Sync unsynced records to Supabase (non-blocking)
    unawaited(_syncLocalToRemote());

    // 3. Subscribe to real-time updates
    _setupRealtimeSubscription();
  }

  Future<void> _syncLocalToRemote() async {
    final client = _supabase;
    if (client == null) return;

    try {
      final unsynced = await _localDb.getUnsyncedClients();
      for (var item in unsynced) {
        try {
          final remoteClient = Map<String, dynamic>.from(item)
            ..remove('is_synced');
          await client.from('clients').upsert(remoteClient);
          await _localDb.markClientAsSynced(item['id'] as String);
        } catch (e) {
          debugPrint('Sync failed for ${item['id']}: $e');
        }
      }

      // Refresh UI if any sync succeeded
      final localList = await _localDb.getClients();
      final localMap = {for (var c in localList) c['id']: c};
      for (var c in _clients) {
        localMap[c['id']] = c;
      }
      _clients = localMap.values.toList();
      _sortClients();
      notifyListeners();
    } catch (e) {
      debugPrint('Remote sync loop error: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final client = _supabase;
    if (client == null) return;

    try {
      final channel = client.channel('public:clients');
      _channel = channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'clients',
            callback: (payload) async {
              if (payload.eventType == PostgresChangeEvent.insert) {
                final newRecord = Map<String, dynamic>.from(payload.newRecord);
                newRecord['is_synced'] = 1;
                await _localDb.insertClientLocally(newRecord);
                final localList = await _localDb.getClients();
                _clients = List<Map<String, dynamic>>.from(localList);
                _sortClients();
                notifyListeners();
              } else if (payload.eventType == PostgresChangeEvent.delete) {
                final deletedId = payload.oldRecord['id'];
                if (deletedId != null) {
                  await _localDb.removeClientLocally(deletedId.toString());
                  _clients.removeWhere((c) => c['id'] == deletedId);
                  notifyListeners();
                }
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Realtime channel setup skipped: $e');
    }
  }

  void _sortClients() {
    _clients.sort((a, b) =>
        (a['created_at']?.toString() ?? '')
            .compareTo(b['created_at']?.toString() ?? ''));
  }

  Future<void> addClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    Position? position;
    try {
      position = await _geoService.getCurrentPosition();
    } catch (e) {
      debugPrint('Geolocation capture failed: $e');
    }

    final newClient = <String, dynamic>{
      'id': const Uuid().v4(),
      'name': trimmed,
      'lat': position?.latitude,
      'lng': position?.longitude,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    };

    // Update UI instantly
    _clients.add(newClient);
    _sortClients();
    notifyListeners();

    // Persist to local SQLite
    await _localDb.insertClientLocally(newClient);

    // Attempt remote sync (non-blocking for UX)
    unawaited(_syncLocalToRemote());
  }

  Future<void> removeClient(String id) async {
    _clients.removeWhere((c) => c['id'] == id);
    notifyListeners();

    await _localDb.removeClientLocally(id);

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('clients').delete().eq('id', id);
      } catch (e) {
        debugPrint('Remote delete failed: $e');
      }
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) return;
    final first = _clients.first;
    await removeClient(first['id'] as String);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
