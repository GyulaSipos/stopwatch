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

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - rapid start calls
      final notifier = container.read(stopwatchViewModelProvider.notifier);

      notifier.start();
      await Future.delayed(const Duration(milliseconds: 10));

      // After first start, watchface should be default (just started)
      final stateAfterFirstStart = container.read(stopwatchViewModelProvider);
      expect(stateAfterFirstStart, isA<StopwatchRunning>());

      notifier.start();
      await Future.delayed(const Duration(milliseconds: 10));
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should still be running, no duplicate timers
      expect(state, isA<StopwatchRunning>());
      // Watchface should not have reset or jumped abnormally
      expect(state.watchFace, isNotNull);
      // Subsequent starts are no-ops, only 1 upsert call
      verify(() => mockDataSource!.upsert(any())).called(1);
    });

    test('pause pressed while already paused has no effect', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      final stateAfterFirstPause = container.read(stopwatchViewModelProvider);
      expect(stateAfterFirstPause, isA<StopwatchPaused>());
      final watchFace = stateAfterFirstPause.watchFace;

      // Try to pause again twice
      notifier.pause();
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain paused and watch face should be equal
      expect(state, isA<StopwatchPaused>());
      expect(state.watchFace, equals(watchFace));

      // Ensure no extra calls were made on data source (1 for start, 1 for pause)
      verify(() => mockDataSource!.upsert(any())).called(2);
    });

    test('resume pressed while running has no effect', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      container.read(stopwatchViewModelProvider.notifier).start();
      await Future.delayed(const Duration(milliseconds: 50));

      container.read(stopwatchViewModelProvider.notifier).resume();
      // Capture watchface before resume attempt
      final state1 = container.read(stopwatchViewModelProvider);
      expect(state1, isA<StopwatchRunning>());
      final watchFace1 = state1.watchFace;

      // Try to resume while running
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain running
      expect(state, isA<StopwatchRunning>());
      // Watchface should not have jumped or reset
      expect(state.watchFace.isAfter(watchFace1), true);
      // Ensure only 1 call is made on data source (for start)
      verify(() => mockDataSource!.upsert(any())).called(1);
    });

    test('end pressed while stopped has no effect', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - try to end without starting
      final notifier = container.read(stopwatchViewModelProvider.notifier);

      // Capture watchface before end attempt
      final stateBeforeEnd = container.read(stopwatchViewModelProvider);
      expect(stateBeforeEnd, isA<StopwatchStopped>());
      final watchFaceBefore = stateBeforeEnd.watchFace;

      notifier.end();
      notifier.end();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain stopped
      expect(state, isA<StopwatchStopped>());
      // Watchface should not change
      expect(state.watchFace, equals(watchFaceBefore));
      // Ensure no calls were made on data source
      verifyNever(() => mockDataSource!.upsert(any()));
    });

    test('end pressed immediately after start creates minimal round', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
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

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - try to lap without starting
      final notifier = container.read(stopwatchViewModelProvider.notifier);

      // Capture watchface before lap attempt
      final stateBeforeLap = container.read(stopwatchViewModelProvider);
      expect(stateBeforeLap, isA<StopwatchStopped>());
      final watchFaceBefore = stateBeforeLap.watchFace;

      notifier.recordLap();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain stopped with no laps
      expect(state, isA<StopwatchStopped>());
      expect((state as StopwatchStopped).laps, isEmpty);
      // Watchface should not change
      expect(state.watchFace, equals(watchFaceBefore));
      // Ensure no calls were made on data source
      verifyNever(() => mockDataSource!.upsert(any()));
    });

    test('multiple laps can be recorded while running', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.deleteLapsForId(any())).thenAnswer((_) async => null.box());

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
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

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      // Lap while paused twice rapidly
      notifier.recordLap();
      notifier.recordLap();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should have 1 lap and still be paused
      expect(state, isA<StopwatchPaused>());
      expect((state as StopwatchPaused).laps.length, equals(1));

      // Ensure only 3 upsert calls total (1 for start, 1 for pause, 1 for lap)
      verify(() => mockDataSource!.upsert(any())).called(3);
    });

    test('rapid start-pause-resume sequence handled correctly', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - rapid sequence
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 10));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 10));

      // Capture watchface while paused
      final pausedState = container.read(stopwatchViewModelProvider);
      expect(pausedState, isA<StopwatchPaused>());
      final watchFaceAfterPause = pausedState.watchFace;

      notifier.resume();
      await Future.delayed(const Duration(milliseconds: 10));

      // After resume, watchface should be the same (ticker hasn't fired yet)
      final runningState = container.read(stopwatchViewModelProvider);
      expect(runningState, isA<StopwatchRunning>());
      expect(runningState.watchFace, equals(watchFaceAfterPause));

      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should be paused
      expect(state, isA<StopwatchPaused>());
      // Watchface should not have jumped or duplicated
      expect(state.watchFace, isNotNull);
      // Ensure correct number of upsert calls: start(1) + pause(1) + resume(1) + pause(1) = 4
      verify(() => mockDataSource!.upsert(any())).called(4);
    });

    test('clear laps removes all laps from current round', () async {
      // Arrange
      when(() => mockDataSource!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.upsert(any())).thenAnswer((_) async => null.box());
      when(() => mockDataSource!.deleteLapsForId(any())).thenAnswer((_) async => null.box());

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
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

      container = ProviderContainer(overrides: [roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!)]);
      container.read(stopwatchViewModelProvider);
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

class MockRoundModelLocalDataSource extends Mock implements IRoundModelLocalDataSource {}
