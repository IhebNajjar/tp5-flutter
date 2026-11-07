import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/queue_provider.dart';

class MockQueueProvider extends Mock implements QueueProvider {}

void main() {
  testWidgets('should display empty state when no clients in queue',
      (WidgetTester tester) async {
    final provider = MockQueueProvider();
    when(() => provider.clients).thenReturn([]);

    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const MaterialApp(home: WaitingRoomScreen()),
      ),
    );

    expect(find.text('No one in queue yet...'), findsOneWidget);
  });

  testWidgets('should display clients when queue has elements',
      (WidgetTester tester) async {
    final provider = MockQueueProvider();
    when(() => provider.clients).thenReturn([
      {
        'id': '1',
        'name': 'Alice',
        'lat': null,
        'lng': null,
        'created_at': '2024-01-01T00:00:00Z',
      }
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const MaterialApp(home: WaitingRoomScreen()),
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('No one in queue yet...'), findsNothing);
  });

  testWidgets('should call removeClient when delete button is tapped',
      (WidgetTester tester) async {
    final provider = MockQueueProvider();
    when(() => provider.clients).thenReturn([
      {
        'id': '10',
        'name': 'Bob',
        'lat': null,
        'lng': null,
        'created_at': '2024-01-01T00:00:00Z',
      }
    ]);
    when(() => provider.removeClient('10')).thenAnswer((_) async {});

    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const MaterialApp(home: WaitingRoomScreen()),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump();

    verify(() => provider.removeClient('10')).called(1);
  });

  testWidgets('should call nextClient when "Next Client" button is tapped',
      (WidgetTester tester) async {
    final provider = MockQueueProvider();
    when(() => provider.clients).thenReturn([
      {
        'id': '1',
        'name': 'Client A',
        'lat': null,
        'lng': null,
        'created_at': '2024-01-01T00:00:00Z',
      }
    ]);
    when(() => provider.nextClient()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const MaterialApp(home: WaitingRoomScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Next Client'));
    await tester.pump();

    verify(() => provider.nextClient()).called(1);
  });
}
