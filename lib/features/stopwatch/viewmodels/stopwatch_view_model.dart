import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/core/runtime_calculations.dart';
import 'package:stopwatch/core/convert_model_to_history_entry.dart';
import 'package:stopwatch/core/stopwatch_values_from_duration.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';
import 'package:stopwatch/features/stopwatch/repositories/stopwatch_repository.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_entry.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

final stopwatchViewModelProvider = NotifierProvider<StopwatchViewModel, StopwatchViewState>(StopwatchViewModel.new);

class StopwatchViewModel extends Notifier<StopwatchViewState> {
  //here for fast lookups
  int? _lastCheckpointTimestamp;
  //the model also acts as internal state, this way we dont need to expose it to UI
  RoundModel? _currentRoundModel;
  StreamSubscription? _tickerSub;

  @override
  StopwatchViewState build() {
    //incremenatally update state
    listenSelf((prev, next) {
      _tickerSub?.cancel();
      if (next is StopwatchRunning && prev != next) {
        //16 milliseconds roughly gives us 60fps
        //This setup prioritizes accuracy and state driven UI instead of performance efficiency.
        //To make it more performant, we could just fake the hundreds of seconds display with a random animation
        //while the clock is running (nobody can read those numbers anyways),
        //and only display the real number when the watch is stopped. That would boost performance 10x
        _tickerSub = Stream.periodic(Duration(milliseconds: 16)).listen((_) {
          state = state.copyWith(
            watchFace: stopwatchValuesFromDuration(calculateTotalRunningDuration(_currentRoundModel?.events)),
            currentLap: state.laps.isEmpty ? null : _stopwatchValuesFromLatestCheckpoint(DateTime.now()),
          );
        });
        //it's here to sync up the ui state one last time after watch is stopped
        //this way we see the same number on the total counter and the first lap,
        //even if the lap was recorded during pause
      } else if ((next is StopwatchPaused || next is StopwatchStopped) && prev.runtimeType != next.runtimeType) {
        state = state.copyWith(
          watchFace: stopwatchValuesFromDuration(calculateTotalRunningDuration(_currentRoundModel?.events)),
          currentLap: state.laps.isEmpty ? null : _stopwatchValuesFromLatestCheckpoint(DateTime.now()),
        );
      }
    });
    ref.onDispose(() {
      //plug up leaky stream when it's no longer needed
      _tickerSub?.cancel();
    });
    //get the initial state
    ref.read(stopwatchRepositoryProvider).getLatestTwo().then((box) {
      if (box.noValue || box.value!.isEmpty) {
        //first time using the app
        state = StopwatchStopped(watchFace: defaultWatchFace);
      } else {
        _currentRoundModel = box.value!.first;
        //we made sure to always get the events in timestamp ASC
        switch (_currentRoundModel!.events.last) {
          case Start(:final timeStamp):
          case Resume(:final timeStamp):
          case Lap(:final timeStamp):
            _lastCheckpointTimestamp = timeStamp;
            state = StopwatchRunning(
              watchFace: stopwatchValuesFromDuration(calculateRunningDurationSinceLastLap(_currentRoundModel!.events)),
              latestEntry: box.value!.length == 2 ? convertModelToHistoryEntry(box.value!.last) : null,
              laps: calculateLapDurations(
                _currentRoundModel!.events,
              ).map((duration) => stopwatchValuesFromDuration(duration)).toList(),
            );
          case Pause():
            state = StopwatchPaused(
              watchFace: stopwatchValuesFromDuration(calculateTotalRunningDuration(_currentRoundModel!.events)),
              latestEntry: box.value!.length == 2 ? convertModelToHistoryEntry(box.value!.last) : null,
              laps: calculateLapDurations(
                _currentRoundModel!.events,
              ).map((duration) => stopwatchValuesFromDuration(duration)).toList(),
            );
          case End():
            state = StopwatchStopped(
              watchFace: stopwatchValuesFromDuration(calculateTotalRunningDuration(_currentRoundModel!.events)),
              latestEntry: box.value!.length == 2 ? convertModelToHistoryEntry(box.value!.last) : null,
              laps: calculateLapDurations(
                _currentRoundModel!.events,
              ).map((duration) => stopwatchValuesFromDuration(duration)).toList(),
            );
        }
      }
    });
    return StopwatchLoading();
  }

  void start() {
    _lastCheckpointTimestamp = _nowStamp;
    state = StopwatchRunning(
      watchFace: defaultWatchFace,
      latestEntry: _currentRoundModel != null ? convertModelToHistoryEntry(_currentRoundModel) : state.latestEntry,
    );
    _currentRoundModel = RoundModel(_nowStamp);
    ref.read(stopwatchRepositoryProvider).upsert(_currentRoundModel!);
  }

  void pause() {
    //boi do i like not needing to write 'state is X' three times
    if (state case StopwatchStopped() || StopwatchLoading() || StopwatchPaused()) return;
    _updateAndStoreCurrentModel(Pause(DateTime.now().millisecondsSinceEpoch));
    state = StopwatchPaused(
      watchFace: state.watchFace,
      latestEntry: state.latestEntry,
      laps: state.laps,
      currentLap: state.currentLap,
    );
  }

  void resume() {
    if (state is! StopwatchPaused) return;
    state = StopwatchRunning(watchFace: state.watchFace, latestEntry: state.latestEntry, laps: state.laps);
    _lastCheckpointTimestamp = _nowStamp;
    _updateAndStoreCurrentModel(Resume(_lastCheckpointTimestamp!));
  }

  void recordLap() async {
    late final int timestamp;
    if (state is StopwatchStopped) return;
    if (state is StopwatchPaused) {
      //while the clock is not running, we lap the time it was stopped at
      //we allow lap during pause, but only once
      if (_currentRoundModel?.events.last is Lap &&
          _currentRoundModel?.events.last.timeStamp == _lastCheckpointTimestamp) {
        return;
      }
      timestamp = _currentRoundModel!.events.last.timeStamp;
    } else {
      timestamp = _nowStamp;
    }

    final values = stopwatchValuesFromDuration(calculateRunningDurationSinceLastLap(_currentRoundModel!.events));
    state = state.copyWith(laps: [...state.laps, values]);
    _lastCheckpointTimestamp = timestamp;
    _updateAndStoreCurrentModel(Lap(timestamp));
  }

  void clearLaps() {
    _currentRoundModel = _currentRoundModel?.copyWith(
      copyEvents: _currentRoundModel!.events.where((element) => element is! Lap).toList(),
    );
    ref.read(stopwatchRepositoryProvider).deleteLapsForId(_currentRoundModel!.id);
    state = state.copyWith(
      laps: [],
      currentLap: null,
      latestEntry: _currentRoundModel!.events.last is End
          ? HistoryEntry(totalTimeRow: state.latestEntry!.totalTimeRow, laps: [])
          : state.latestEntry,
    );
  }

  void end() {
    if (state case StopwatchLoading() || StopwatchStopped()) return;
    if (_currentRoundModel == null) return;
    _updateAndStoreCurrentModel(End(state is StopwatchPaused ? _currentRoundModel!.events.last.timeStamp : _nowStamp));
    state = StopwatchStopped(
      watchFace: state.watchFace,
      latestEntry: convertModelToHistoryEntry(_currentRoundModel),
      //since we done with this round, add the last lap to the laps
      laps: [...state.laps, ?state.currentLap],
    );
  }

  void _updateAndStoreCurrentModel(StopWatchEvent event) {
    final events = [..._currentRoundModel!.events, event];
    final totalRunningDuration = event is End ? calculateTotalRunningDuration(events).inMilliseconds : null;
    _currentRoundModel = _currentRoundModel!.copyWith(copyEvents: events, totalRunningDuration: totalRunningDuration);
    ref.read(stopwatchRepositoryProvider).upsert(_currentRoundModel!);
  }

  Watchface _stopwatchValuesFromLatestCheckpoint(DateTime current) {
    if (_lastCheckpointTimestamp == null) return defaultWatchFace;
    final duration = current.difference(DateTime.fromMillisecondsSinceEpoch(_lastCheckpointTimestamp!));
    return stopwatchValuesFromDuration(duration);
  }

  int get _nowStamp => DateTime.now().millisecondsSinceEpoch;
}
