import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/repositories/stopwatch_repository.dart';
import 'package:stopwatch/features/stopwatch/services/round_model_local_data_source.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

import 'mocks/mock_local_data_source.dart';

void main() {
  setUpAll(() {
    // Register mocks for Mocktail
    registerFallbackValue(RoundModel(0));
    registerFallbackValue(<RoundModel>[]);
    registerFallbackValue(<RoundModel?>[]);
  });

  group('StopwatchViewModel', () {
    MockRoundModelLocalDataSource? mockDataSource;
    MockStopwatchRepository? mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockDataSource = MockRoundModelLocalDataSource();
      mockRepository = MockStopwatchRepository();

      // Setup providers with mocks
      container = ProviderContainer(
        overrides: [
          roundModelLocalDataSourceProvider.overrideWithValue(mockDataSource!),
          stopwatchRepositoryProvider.overrideWith((ref) => mockRepository!),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is Loading', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());

      // Act
      final state = container.read(stopwatchViewModelProvider);

      // Assert
      expect(state, isA<StopwatchLoading>());
    });

    test('first time user shows Stopped state with default watchface', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      // Need to wait for async initialization
      container.read(stopwatchViewModelProvider.notifier).build();
      // Give the async operation time to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      final state = container.read(stopwatchViewModelProvider);

      // Assert
      expect(state, isA<StopwatchStopped>());
      expect((state as StopwatchStopped).watchFace, equals(defaultWatchFace));
    });

    test('pressing start button starts stopwatch and changes state to Running', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });
      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 500));
      final state = container.read(stopwatchViewModelProvider);

      // Assert
      expect(state, isA<StopwatchRunning>());
    });

    test('pressing pause button pauses stopwatch and changes state to Paused', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act - start first
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert
      expect(state, isA<StopwatchPaused>());
    });

    test('pressing resume button resumes stopwatch and changes state to Running', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act - start, pause, then resume
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.resume();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert
      expect(state, isA<StopwatchRunning>());
    });

    test('pressing end button stops stopwatch and changes state to Stopped', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.delayed(const Duration(milliseconds: 100));

      // Act - start, then end
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.end();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert
      expect(state, isA<StopwatchStopped>());
    });

    test('elapsed time increases over time when stopwatch is running', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act - start stopwatch
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();

      // Wait for some time to pass
      await Future.delayed(const Duration(milliseconds: 100));

      final firstState = container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 100));
      final secondState = container.read(stopwatchViewModelProvider);

      // Assert - state should be Running
      expect(firstState, isA<StopwatchRunning>());
      expect(secondState, isA<StopwatchRunning>());
      // Note: The exact time values may vary due to async nature of the ticker
      expect(secondState.watchFace.isAfter(firstState.watchFace), true);
    });

    test('elapsed time stops increasing when paused', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act - start, run for a bit, then pause
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 100));
      notifier.pause();

      // Capture state while paused
      await Future.delayed(const Duration(milliseconds: 50));
      final pausedState1 = container.read(stopwatchViewModelProvider);
      await Future.delayed(const Duration(milliseconds: 50));
      final pausedState2 = container.read(stopwatchViewModelProvider);

      // Assert
      expect(pausedState1, isA<StopwatchPaused>());
      expect(pausedState2, isA<StopwatchPaused>());

      // The watch face should remain the same while paused
      expect((pausedState1 as StopwatchPaused).watchFace, equals((pausedState2 as StopwatchPaused).watchFace));
    });

    test('end stops elapsed time', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act - start, run, then end (reset)
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 150));
      notifier.end();
      await Future.delayed(const Duration(milliseconds: 50));

      final stoppedState = container.read(stopwatchViewModelProvider);

      // Assert
      expect(stoppedState, isA<StopwatchStopped>());
    });

    test('pressing start multiple times without pause does not cause unexpected behavior', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act - start multiple times
      container.read(stopwatchViewModelProvider.notifier).start();
      await Future.delayed(const Duration(milliseconds: 500));

      container.read(stopwatchViewModelProvider.notifier).start();
      await Future.delayed(const Duration(milliseconds: 50));

      // Start again
      container.read(stopwatchViewModelProvider.notifier).start();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should still be running, no crashes or weird states
      expect(state, isA<StopwatchRunning>());
      // Only the first start should persist; subsequent starts are no-ops (already running)
      verify(() => mockRepository!.upsert(any())).called(1);

      // Watchface should be valid
      expect(state.watchFace, isNotNull);
    });

    test('pause button does nothing when already paused', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      notifier.start();
      await Future.delayed(const Duration(milliseconds: 50));
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      // Capture watchface before second pause
      final watchFaceBefore = (container.read(stopwatchViewModelProvider) as StopwatchPaused).watchFace;

      // Try to pause again
      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should still be paused
      expect(state, isA<StopwatchPaused>());
      // Watchface should not change on duplicate pause
      expect(state.watchFace, equals(watchFaceBefore));
      // Only 2 upsert calls: 1 for start, 1 for pause
      verify(() => mockRepository!.upsert(any())).called(2);
    });

    test('pause button does nothing when stopped', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });
      // Act - capture watchface before pause
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      final stateBefore = container.read(stopwatchViewModelProvider);
      final watchFaceBefore = (stateBefore as StopwatchStopped).watchFace;

      notifier.pause();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain stopped
      expect(state, isA<StopwatchStopped>());
      // Watchface should not change
      expect(state.watchFace, equals(watchFaceBefore));
      // No repository calls should be made
      verifyNever(() => mockRepository!.upsert(any()));
    });

    test('resume button does nothing when not paused', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act - capture watchface before resume
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      final stateBefore = container.read(stopwatchViewModelProvider);
      final watchFaceBefore = (stateBefore as StopwatchStopped).watchFace;

      notifier.resume();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain stopped
      expect(state, isA<StopwatchStopped>());
      // Watchface should not change
      expect(state.watchFace, equals(watchFaceBefore));
      // No repository calls should be made
      verifyNever(() => mockRepository!.upsert(any()));
    });

    test('end button does nothing when already stopped', () async {
      // Arrange
      when(() => mockRepository!.getLatestTwo()).thenAnswer((_) async => null.box());
      when(() => mockRepository!.upsert(any())).thenAnswer((_) async => null.box());
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 1000));
        return container.read(stopwatchViewModelProvider) is StopwatchLoading;
      });

      // Act - capture watchface before end
      final notifier = container.read(stopwatchViewModelProvider.notifier);
      final stateBefore = container.read(stopwatchViewModelProvider);
      final watchFaceBefore = (stateBefore as StopwatchStopped).watchFace;

      notifier.end();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(stopwatchViewModelProvider);

      // Assert - should remain stopped
      expect(state, isA<StopwatchStopped>());
      // Watchface should not change
      expect(state.watchFace, equals(watchFaceBefore));
      // No repository calls should be made
      verifyNever(() => mockRepository!.upsert(any()));
    });
  });
}

class MockStopwatchRepository extends Mock implements IStopwatchRepository {}
