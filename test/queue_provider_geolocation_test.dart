import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/queue_provider.dart';

class MockGeolocationService extends Mock implements GeolocationService {}

class MockQueueProvider extends Mock implements QueueProvider {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('QueueProvider Geolocation Tests', () {
    test('addClient saves client with geolocation', () async {
      final mockGeo = MockGeolocationService();
      final mockPos = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      when(() => mockGeo.getCurrentPosition()).thenAnswer((_) async => mockPos);

      final localDb = LocalQueueService(inMemory: true);
      await localDb.clear();
      final provider = QueueProvider(geoService: mockGeo, localDb: localDb);

      await provider.addClient('Test User');

      final client = provider.clients.last;
      expect(client['lat'], 37.7749);
      expect(client['lng'], -122.4194);
    });

    test('addClient handles null geolocation gracefully', () async {
      final mockGeo = MockGeolocationService();
      when(() => mockGeo.getCurrentPosition()).thenAnswer((_) async => null);

      final localDb = LocalQueueService(inMemory: true);
      await localDb.clear();
      final provider = QueueProvider(geoService: mockGeo, localDb: localDb);

      await provider.addClient('No Geo User');

      final client = provider.clients.last;
      expect(client['lat'], isNull);
      expect(client['lng'], isNull);
    });
  });

  group('Widget Test for Location Display', () {
    testWidgets('Displays location when available', (tester) async {
      final provider = MockQueueProvider();
      when(() => provider.clients).thenReturn([
        {
          'id': '1',
          'name': 'Sam',
          'lat': 51.5074,
          'lng': -0.1278,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider<QueueProvider>.value(
          value: provider,
          child: const MaterialApp(home: WaitingRoomScreen()),
        ),
      );

      expect(find.text('Sam'), findsOneWidget);
      expect(find.textContaining('51.5074'), findsOneWidget);
    });

    testWidgets('Displays fallback message when location is not captured', (tester) async {
      final provider = MockQueueProvider();
      when(() => provider.clients).thenReturn([
        {
          'id': '2',
          'name': 'Bob',
          'lat': null,
          'lng': null,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider<QueueProvider>.value(
          value: provider,
          child: const MaterialApp(home: WaitingRoomScreen()),
        ),
      );

      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('📍 Location not captured'), findsOneWidget);
    });
  });
}
