import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/core/calculate_total_running_duration.dart';
import 'package:stopwatch/core/convert_model_to_history_entry.dart';
import 'package:stopwatch/core/stopwatch_values_from_duration.dart';
import 'package:stopwatch/core/total_running_duration_since_last_lap_or_start.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';
import 'package:stopwatch/features/stopwatch/repositories/stopwatch_repository.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

final stopwatchViewModelProvider = NotifierProvider<StopwatchViewModel, StopwatchViewState>(StopwatchViewModel.new);

class StopwatchViewModel extends Notifier<StopwatchViewState> {
  //here for fat lookups
  int? _lastCheckpointTimestamp;
  //the model also acts as internal state, this way we dont need to expose it to UI
  RoundModel? _currentRoundModel;
  StreamSubscription? _tickerSub;

  @override
  StopwatchViewState build() {
    listenSelf((prev, next) {
      _tickerSub?.cancel();
      if (next is Running && prev != next) {
        //16 milliseconds roughly gives us 60fps
        //This setup prioritizes accuracy and state driven UI instead of performance efficiency.
        //To make it more performant, we could just fake the hundreds of seconds display with a random animation
        //while the clock is running (nobody can read those numbers anyways),
        //and only display the real number when the watch is stopped. That would boost performance 10x
        _tickerSub = Stream.periodic(Duration(milliseconds: 16)).listen((_) {
          state = state.copyWith(
            watchFace: stopwatchValuesFromDuration(
              calculateTotalRunningDuration(_currentRoundModel!.events, isCurrentlyRunning: true),
            ),
            currentLap: state.laps.isEmpty ? null : _stopwatchValuesFromLatestCheckpoint(DateTime.now()),
          );
        });
        //it's here to sync up the ui state one last time after watch is stopped
        //this way we see the same number on the total counter and the first lap,
        //even if the lap was recorded during pause
      } else if ((next is Paused || next is End) && prev.runtimeType != next.runtimeType) {
        state = state.copyWith(
          watchFace: stopwatchValuesFromDuration(
            calculateTotalRunningDuration(_currentRoundModel!.events, isCurrentlyRunning: false),
          ),
          currentLap: state.laps.isEmpty ? null : _stopwatchValuesFromLatestCheckpoint(DateTime.now()),
        );
      }
    });
    ref.onDispose(() {
      //plug up leaky stream when it's no longer needed
      _tickerSub?.cancel();
    });
    ref.read(stopwatchRepositoryProvider).getLatestTwo().then((box) {
      if (box.noValue || box.value!.isEmpty) {
        //first time using the app
        state = Stopped(watchFace: defaultWatchFace);
      } else {
        _currentRoundModel = box.value!.last;
        //we made sure to always get the events in timestamp ASC
        switch (box.value!.last!.events.last) {
          case Start(:final timeStamp):
          case Resume(:final timeStamp):
          case Lap(:final timeStamp):
            _lastCheckpointTimestamp = timeStamp;
            state = Running(
              watchFace: stopwatchValuesFromDuration(
                calculateTotalRunningDuration(box.value!.last!.events, isCurrentlyRunning: true),
              ),
              latestEntry: box.value!.length == 2 ? convertModelToHistoryEntry(box.value!.first) : null,
            );
          case Pause():
            state = Paused(
              watchFace: stopwatchValuesFromDuration(calculateTotalRunningDuration(box.value!.last!.events)),
              latestEntry: box.value!.length == 2 ? convertModelToHistoryEntry(box.value!.first) : null,
            );
          case End():
            state = Stopped(
              watchFace: stopwatchValuesFromDuration(calculateTotalRunningDuration(box.value!.last!.events)),
              latestEntry: box.value!.length == 2 ? convertModelToHistoryEntry(box.value!.first) : null,
            );
        }
      }
    });
    return Loading();
  }

  void start() {
    _lastCheckpointTimestamp = _nowStamp;
    state = Running(
      watchFace: defaultWatchFace,
      latestEntry: _currentRoundModel != null ? convertModelToHistoryEntry(_currentRoundModel) : state.latestEntry,
    );
    _currentRoundModel = RoundModel(_nowStamp);
    ref.read(stopwatchRepositoryProvider).upsert(_currentRoundModel!);
  }

  void pause() {
    //boi do i like not needing to write 'state is' three times
    if (state case Stopped() || Loading() || Paused()) return;
    _updateAndStoreCurrentModel(Pause(DateTime.now().millisecondsSinceEpoch));
    state = Paused(
      watchFace: state.watchFace,
      latestEntry: state.latestEntry,
      laps: state.laps,
      currentLap: state.currentLap,
    );
  }

  void resume() {
    if (state is! Paused) return;
    state = Running(watchFace: state.watchFace, latestEntry: state.latestEntry, laps: state.laps);
    _lastCheckpointTimestamp = _nowStamp;
    _updateAndStoreCurrentModel(Resume(_lastCheckpointTimestamp!));
  }

  void recordLap() async {
    late final int timestamp;
    if (state is Stopped) return;
    if (state is Paused) {
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

    final values = stopwatchValuesFromDuration(
      totalRunningDurationSinceLastLapOrStart(_currentRoundModel!.events, isCurrentlyRunning: state is Running),
    );
    state = state.copyWith(laps: [...state.laps, values]);
    _lastCheckpointTimestamp = timestamp;
    _updateAndStoreCurrentModel(Lap(timestamp));
  }

  void end() {
    if (state case Loading() || Stopped()) return;
    if (_currentRoundModel == null) return;
    _updateAndStoreCurrentModel(End(_nowStamp));
    state = Stopped(
      watchFace: state.watchFace,
      latestEntry: convertModelToHistoryEntry(_currentRoundModel),
      //since we done with this round, add the last lap to the laps
      laps: [...state.laps, ?state.currentLap],
    );
  }

  void _updateAndStoreCurrentModel(StopWatchEvent event) {
    final events = [..._currentRoundModel!.events, event];
    final totalRunningDuration = event is End
        ? calculateTotalRunningDuration(events, isCurrentlyRunning: false).inMilliseconds
        : null;
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
