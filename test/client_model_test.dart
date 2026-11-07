import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/client.dart';

void main() {
  group('Client Model Tests', () {
    test('Client.fromMap should correctly deserialize map data with location', () {
      final now = DateTime.now().toUtc();
      final map = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'name': 'Alice Smith',
        'lat': 40.7128,
        'lng': -74.0060,
        'created_at': now.toIso8601String(),
        'is_synced': 1,
      };

      final client = Client.fromMap(map);

      expect(client.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(client.name, 'Alice Smith');
      expect(client.lat, 40.7128);
      expect(client.lng, -74.0060);
      expect(client.isSynced, 1);
      expect(client.createdAt.toIso8601String(), now.toIso8601String());
    });

    test('Client.toMap should correctly serialize client data with location', () {
      final now = DateTime.now().toUtc();
      final client = Client(
        id: '987-xyz',
        name: 'Bob Jones',
        lat: 51.5074,
        lng: -0.1278,
        createdAt: now,
        isSynced: 0,
      );

      final map = client.toMap();

      expect(map['id'], '987-xyz');
      expect(map['name'], 'Bob Jones');
      expect(map['lat'], 51.5074);
      expect(map['lng'], -0.1278);
      expect(map['is_synced'], 0);
      expect(map['created_at'], now.toIso8601String());
    });

    test('toString returns formatted string representation', () {
      final now = DateTime.parse('2026-10-13T09:00:00Z');
      final client = Client(
        id: '1',
        name: 'John',
        lat: 12.34,
        lng: 56.78,
        createdAt: now,
      );

      expect(
        client.toString(),
        'Client(id: 1, name: John, lat: 12.34, lng: 56.78, created_at: 2026-10-13 09:00:00.000Z, is_synced: 0)',
      );
    });
  });
}
