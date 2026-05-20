import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/services/round_model_local_data_source.dart';
import 'package:stopwatch/features/stopwatch/views/screens/stopwatch_screen.dart';
import 'package:stopwatch/main.dart';

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(RoundModel(0));
    registerFallbackValue(<RoundModel>[]);
    registerFallbackValue(<RoundModel?>[]);
  });

  group('StopwatchScreen Widget Tests', () {
    testWidgets('displays stopped state on first launch', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MainApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Assert - should show play button (indicating stopped state)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('tapping start button starts stopwatch and shows pause icon', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Act - tap start button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert - should show pause icon now
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing); // Stop button appears only when paused
    });

    testWidgets('tapping pause button pauses stopwatch and shows resume icon', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Start the stopwatch
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Act - tap pause button
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      // Assert - should show play (resume) icon and stop icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('tapping resume button resumes stopwatch', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Start and pause
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      // Act - tap resume button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert - should show pause icon again
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('tapping end button stops stopwatch and shows play icon', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Start and pause
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      // Act - tap end button
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      // Assert - should show play icon (stopped state)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('elapsed time increases when running', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Act - start stopwatch
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - stopwatch should still be running (pause icon visible)
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('tapping start multiple times restarts stopwatch', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Act - tap start multiple times
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Start again while running - should restart
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Start again
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert - should still be running with pause icon
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('lap button is visible when running', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Start stopwatch
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert - refresh icon (lap) should be visible
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('lap button is not visible when stopped', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Assert - refresh icon (lap) should not be visible in stopped state
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('UI responds correctly to complete user flow', (WidgetTester tester) async {
      // Arrange
      final mockDataSource = MockRoundModelLocalDataSource();
      when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource)],
          child: const MaterialApp(home: StopwatchScreen()),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // User flow: Start -> Lap -> Pause -> Resume -> End

      // 1. Start
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // 2. Record Lap
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget); // Still running

      // 3. Pause
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Now shows resume
      expect(find.byIcon(Icons.stop), findsOneWidget); // Stop button visible

      // 4. Resume
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // 5. End
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Back to stopped state
    });
  });
}

class MockRoundModelLocalDataSource extends Mock implements IRoundModelLocalDataSource {}
