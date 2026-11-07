import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/queue_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic value) onValue,
      {Function? onError}) {
    return Future.value([]).then(onValue, onError: onError);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    registerFallbackValue(<String, dynamic>{});
  });

  test('addClient saves locally and syncs to Supabase via upsert', () async {
    final mockClient = MockSupabaseClient();
    final mockQueryBuilder = MockSupabaseQueryBuilder();
    final fakeFilterBuilder = FakePostgrestFilterBuilder();

    when(() => mockClient.from('clients')).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.upsert(any())).thenAnswer((_) => fakeFilterBuilder);

    final localDb = LocalQueueService(inMemory: true);
    await localDb.clear();
    final provider = QueueProvider(supabase: mockClient, localDb: localDb);

    await provider.addClient('Alice');

    expect(provider.clients.length, 1);
    expect(provider.clients.first['name'], 'Alice');
  });
}
