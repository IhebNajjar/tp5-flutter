import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/local_queue_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    // Use in-memory database for tests
    databaseFactory = databaseFactoryFfi;
  });

  test('insertClientLocally adds a record to the database', () async {
    final service = LocalQueueService(inMemory: true);
    await service.clear();
    await service.insertClientLocally({
      'id': 'test-123',
      'name': 'Alice',
      'lat': 40.71,
      'lng': -74.00,
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 0,
    });

    final clients = await service.getUnsyncedClients();
    expect(clients.length, 1);
    expect(clients[0]['name'], 'Alice');
  });

  test('markClientAsSynced marks record as synced', () async {
    final service = LocalQueueService(inMemory: true);
    await service.clear();
    await service.insertClientLocally({
      'id': 'test-456',
      'name': 'Bob',
      'lat': 10.0,
      'lng': 20.0,
      'created_at': '2024-01-01T01:00:00Z',
      'is_synced': 0,
    });

    await service.markClientAsSynced('test-456');
    final unsynced = await service.getUnsyncedClients();
    expect(unsynced.length, 0);

    final all = await service.getClients();
    final bob = all.firstWhere((c) => c['id'] == 'test-456');
    expect(bob['is_synced'], 1);
  });
}
