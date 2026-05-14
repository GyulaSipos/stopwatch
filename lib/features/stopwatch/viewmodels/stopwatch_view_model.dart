import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';
import 'package:stopwatch/features/stopwatch/repositories/stopwatch_repository.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

final stopwatchViewModelProvider = NotifierProvider<StopwatchViewModel, StopwatchViewState>(StopwatchViewModel.new);

class StopwatchViewModel extends Notifier<StopwatchViewState> {
  int? _lastCheckpointTimestamp;
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
            watchFace: _stopwatchValuesFromDuration(
              _totalRunningDuration(_currentRoundModel!.events, isCurrentlyRunning: true),
            ),

            currentLap: state.laps.isEmpty ? null : _stopwatchValuesFromLatestCheckpoint(DateTime.now()),
          );
        });
        //it's here to sync up the ui state one last time after watch is stopped
      } else if ((next is Paused || next is End) && prev.runtimeType != next.runtimeType) {
        state = state.copyWith(
          watchFace: _stopwatchValuesFromDuration(
            _totalRunningDuration(_currentRoundModel!.events, isCurrentlyRunning: false),
          ),
          currentLap: state.laps.isEmpty ? null : _stopwatchValuesFromLatestCheckpoint(DateTime.now()),
        );
      }
    });
    ref.onDispose(() {
      _tickerSub?.cancel();
    });
    ref.read(stopwatchRepositoryProvider).getLatestTwo().then((box) {
      if (box.noValue || box.value!.isEmpty) {
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
              watchFace: _stopwatchValuesFromDuration(
                _totalRunningDuration(box.value!.last!.events, isCurrentlyRunning: true),
              ),
              latestEntry: box.value!.length == 2 ? _convertModelToHistoryEntry(box.value!.first) : null,
            );
          case Pause():
            state = Paused(
              watchFace: _stopwatchValuesFromDuration(_totalRunningDuration(box.value!.last!.events)),
              latestEntry: box.value!.length == 2 ? _convertModelToHistoryEntry(box.value!.first) : null,
            );
          case End():
            state = Stopped(
              watchFace: _stopwatchValuesFromDuration(_totalRunningDuration(box.value!.last!.events)),
              latestEntry: box.value!.length == 2 ? _convertModelToHistoryEntry(box.value!.first) : null,
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
      latestEntry: _currentRoundModel != null ? _convertModelToHistoryEntry(_currentRoundModel) : state.latestEntry,
    );
    _currentRoundModel = RoundModel(_nowStamp);
    ref.read(stopwatchRepositoryProvider).upsert(_currentRoundModel!);
  }

  void pause() {
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
    final now = DateTime.now();
    state = Running(watchFace: state.watchFace, latestEntry: state.latestEntry, laps: state.laps);
    _lastCheckpointTimestamp = now.millisecondsSinceEpoch;
    _updateAndStoreCurrentModel(Resume(_lastCheckpointTimestamp!));
  }

  void recordLap() async {
    late final int timestamp;
    if (state is Paused) {
      //while the clock is not running, we lap the time it was stopped
      //we allow lap during pause, but only once
      if (_currentRoundModel?.events.last is Lap &&
          _currentRoundModel?.events.last.timeStamp == _lastCheckpointTimestamp) {
        return;
      }
      timestamp = _currentRoundModel!.events.last.timeStamp;
    } else {
      timestamp = _nowStamp;
    }

    final values = _stopwatchValuesFromDuration(
      _totalRunningDurationSinceLastLapOrStart(_currentRoundModel!.events, isCurrentlyRunning: state is Running),
    );
    state = state.copyWith(laps: [...state.laps, values]);
    _lastCheckpointTimestamp = timestamp;
    _updateAndStoreCurrentModel(Lap(timestamp));
  }

  void end() {
    if (state case Loading() || Stopped()) return;
    if (_currentRoundModel == null) return;
    state = Stopped(
      watchFace: state.watchFace,
      latestEntry: state.latestEntry,
      //since we done with this round, add the last lap to the laps
      laps: [...state.laps, ?state.currentLap],
    );
    _updateAndStoreCurrentModel(End(_nowStamp));
  }

  void _updateAndStoreCurrentModel(StopWatchEvent event) {
    _currentRoundModel = _currentRoundModel!.copyWith(copyEvents: [..._currentRoundModel!.events, event]);
    ref.read(stopwatchRepositoryProvider).upsert(_currentRoundModel!);
  }

  Watchface _stopwatchValuesFromLatestCheckpoint(DateTime current) {
    if (_lastCheckpointTimestamp == null) return defaultWatchFace;
    final duration = current.difference(DateTime.fromMillisecondsSinceEpoch(_lastCheckpointTimestamp!));
    return _stopwatchValuesFromDuration(duration);
  }

  HistoryEntry? _convertModelToHistoryEntry(RoundModel? model) {
    if (model == null) return null;

    return (
      DateTime.fromMillisecondsSinceEpoch(model.events.first.timeStamp),
      _stopwatchValuesFromDuration(_totalRunningDuration(model.events)),
    );
  }

  int get _nowStamp => DateTime.now().millisecondsSinceEpoch;

  Duration _totalRunningDurationSinceLastLapOrStart(List<StopWatchEvent> events, {bool isCurrentlyRunning = false}) {
    final index = events.lastIndexWhere((event) => event is Lap || event is Start);
    bool wasWatchStoppedInThePreviousLap = index == 0 || events.elementAtOrNull(index - 1) is Pause;
    //opening the ledger in a wsay the starting Laps condition is counted
    int totalDuration = wasWatchStoppedInThePreviousLap ? 0 : 0 - events[index].timeStamp;
    for (final event in [
      ...events.sublist(index),
      if (isCurrentlyRunning) End(_nowStamp),
    ]) {
      if (event case Start() || Resume()) {
        totalDuration -= event.timeStamp;
      } else if (event case Pause() || End()) {
        totalDuration += event.timeStamp;
      }
    }
    return Duration(milliseconds: totalDuration);
  }

  Duration _totalRunningDuration(List<StopWatchEvent> events, {bool isCurrentlyRunning = false}) {
    int totalDuration = 0;
    for (final event in [...events, if (isCurrentlyRunning) End(_nowStamp)]) {
      if (event case Start() || Resume()) {
        totalDuration -= event.timeStamp;
      } else if (event case Pause() || End()) {
        totalDuration += event.timeStamp;
      }
    }
    return Duration(milliseconds: totalDuration);
  }

  Watchface _stopwatchValuesFromDuration(Duration duration) {
    final totalMinutes = duration.inMinutes % 60;
    final totalSeconds = duration.inSeconds % 60;
    final totalMilliseconds = duration.inMilliseconds % 1000;
    return (
      totalMinutes ~/ 10,
      totalMinutes % 10,
      totalSeconds ~/ 10,
      totalSeconds % 10,
      totalMilliseconds ~/ 100,
      (totalMilliseconds ~/ 10) % 10,
    );
  }
}
