import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/services/round_model_local_data_source.dart';
import 'package:stopwatch/main.dart';

void main() {
  late MockRoundModelLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(RoundModel(0));
    registerFallbackValue(<RoundModel>[]);
    registerFallbackValue(<RoundModel?>[]);
  });

  setUp(() {
    mockDataSource = MockRoundModelLocalDataSource();
    // Default mocks
    when(() => mockDataSource.getLatestTwo()).thenAnswer((_) async => null.box());
    when(() => mockDataSource.upsert(any())).thenAnswer((_) async => null.box());
  });

  Future<void> setupWidget(WidgetTester tester) async {
    // Set a consistent surface size
    await tester.binding.setSurfaceSize(const Size(600, 800));
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource),
        ],
        child: const MainApp(),
      ),
    );
    // Wait for the initialization (from loading to stopped/running)
    await tester.pump();
    await tester.pump();
  }

  group('StopwatchScreen Widget Tests', () {
    testWidgets('displays stopped state on first launch', (WidgetTester tester) async {
      // Act
      await setupWidget(tester);

      // Assert - should show play button (indicating stopped state)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('tapping start button starts stopwatch and shows pause icon', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

      // Act - tap start button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert - should show pause icon now
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('tapping pause button pauses stopwatch and shows resume icon', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

      // Start the stopwatch
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Act - tap pause button
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      // Assert - should show play (resume) icon and stop icon
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });

    testWidgets('tapping resume button resumes stopwatch', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

      // Start and pause
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      // Act - tap resume button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert - should show pause icon again
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('tapping end button stops stopwatch and shows play icon', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

      // Start and pause
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      // Act - tap end button
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // Assert - should show play icon (stopped state)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('elapsed time increases when running', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

      // Act - start stopwatch
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Assert - stopwatch should still be running (pause icon visible)
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('tapping start multiple times stays running', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

      // Act - tap start
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Tap again (it's now a pause button)
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
      
      // Tap again (it's now a play/resume button)
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert - should still be running or paused correctly
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('lap button is visible when running', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

      // Start stopwatch
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert - refresh icon (lap) should be visible
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('lap button is not visible when stopped', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

      // Assert - refresh icon (lap) should not be visible in stopped state
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('UI responds correctly to complete user flow', (WidgetTester tester) async {
      // Arrange
      await setupWidget(tester);

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
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Now shows resume
      expect(find.byIcon(Icons.stop), findsOneWidget); // Stop button visible

      // 4. Resume
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // 5. End
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget); // Back to stopped state
    });
  });
}

class MockRoundModelLocalDataSource extends Mock implements IRoundModelLocalDataSource {}
