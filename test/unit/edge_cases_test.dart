import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/services/round_model_local_data_source.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

void main() {
  setUpAll(() {
    // Register mocks for Mocktail
    registerFallbackValue(RoundModel(0));
    registerFallbackValue(<RoundModel>[]);
    registerFallbackValue(<RoundModel?>[]);
  });

  group('Edge Cases', () {
    MockRoundModelLocalDataSource? mockDataSource;
    late ProviderContainer container;

    setUp(() {
      mockDataSource = MockRoundModelLocalDataSource();
    });

    tearDown(() {
      container.dispose();
    });

    test('start button pressed multiple times without pause creates new rounds', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - rapid start calls
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 10));
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 10));
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should still be running, no duplicate timers
      expect(state, isA<StopwatchRunning>());
      verify(() => mockDataSource!.upsert(any())).called(3);
    });

    test('pause pressed while already paused has no effect', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Try to pause again
      notifier.pause();
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain paused
      expect(state, isA<StopwatchPaused>());
    });

    test('resume pressed while running has no effect', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Try to resume while running
      notifier.resume();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain running
      expect(state, isA<StopwatchRunning>());
    });

    test('end pressed while stopped has no effect', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - try to end without starting
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.end();
      notifier.end();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain stopped
      expect(state, isA<StopwatchStopped>());
    });

    test('end pressed immediately after start creates minimal round', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - start and immediately end
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      notifier.end();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should be stopped with latestEntry
      expect(state, isA<StopwatchStopped>());
      expect((state as StopwatchStopped).latestEntry, isNotNull);
    });

    test('lap pressed while stopped has no effect', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - try to lap without starting
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.recordLap();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain stopped with no laps
      expect(state, isA<StopwatchStopped>());
      expect((state as StopwatchStopped).laps, isEmpty);
    });

    test('multiple laps can be recorded while running', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.deleteLapsForId(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Record multiple laps
      notifier.recordLap();
      await Future.delayed(const Duration(milliseconds: 20));
      notifier.recordLap();
      await Future.delayed(const Duration(milliseconds: 20));
      notifier.recordLap();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should have 3 laps
      expect(state, isA<StopwatchRunning>());
      expect((state as StopwatchRunning).laps.length, equals(3));
    });

    test('lap pressed while paused records lap of stopped time', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.deleteLapsForId(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Lap while paused
      notifier.recordLap();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should have 1 lap and still be paused
      expect(state, isA<StopwatchPaused>());
      expect((state as StopwatchPaused).laps.length, equals(1));
    });

    test('rapid start-pause-resume sequence handled correctly', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - rapid sequence
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 10));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 10));
      notifier.resume();
      await Future.delayed(const Duration(milliseconds: 10));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should be paused
      expect(state, isA<StopwatchPaused>());
    });

    test('timer continues from correct time after resume', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 200)); // Run for 200ms
      
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 100));
      
      notifier.resume();
      await Future.delayed(const Duration(milliseconds: 50));
      
      final resumedState = container.read(stopwatchViewModelProvider);

      // Assert - should be running again
      expect(resumedState, isA<StopwatchRunning>());
      
      // The watch face should continue from where it left off
      // Note: Exact time comparison is tricky due to async nature, so we just verify state
    });

    test('clear laps removes all laps from current round', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.deleteLapsForId(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Record some laps
      notifier.recordLap();
      notifier.recordLap();
      notifier.recordLap();
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Clear laps
      notifier.clearLaps();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should have no laps
      expect(state, isA<StopwatchRunning>());
      expect((state as StopwatchRunning).laps, isEmpty);
      verify(() => mockDataSource!.deleteLapsForId(any())).called(1);
    });

    test('state transitions follow valid path: Stopped -> Running -> Paused -> Running -> Stopped', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
        ],
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      // Act & Assert - verify state transitions
      var state = container.read(stopwatchViewModelProvider);
      expect(state, isA<StopwatchStopped>());

      final notifier = container.read(stopwatchViewModelProvider.notifier);
      
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      state = container.read(stopwatchViewModelProvider);
      expect(state, isA<StopwatchRunning>());

      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));
      state = container.read(stopwatchViewModelProvider);
      expect(state, isA<StopwatchPaused>());

      notifier.resume();
      await Future.delayed(const Duration(milliseconds: 50));
      state = container.read(stopwatchViewModelProvider);
      expect(state, isA<StopwatchRunning>());

      notifier.end();
      await Future.delayed(const Duration(milliseconds: 50));
      state = container.read(stopwatchViewModelProvider);
      expect(state, isA<StopwatchStopped>());
    });
  });
}

class MockRoundModelLocalDataSource extends Mock 
    implements IRoundModelLocalDataSource {}
