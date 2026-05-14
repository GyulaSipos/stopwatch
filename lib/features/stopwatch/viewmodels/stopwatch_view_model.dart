import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';
import 'package:stopwatch/features/stopwatch/repositories/stopwatch_repository.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

final stopwatchViewModelProvider = Provider(
  (ref) => StopwatchViewModel(ref.watch(stopwatchRepositoryProvider)),
);

class StopwatchViewModel extends Notifier<StopwatchViewState> {
  final IStopwatchRepository _repository;
  int? _lastCheckpointTimestamp;
  RoundModel? _currentRoundModel;
  StreamSubscription? _tickerSub;

  StopwatchViewModel(this._repository);

  @override
  StopwatchViewState build() {
    listenSelf((_, next) {
      if (next is Running) {
        _tickerSub?.cancel();
        //16 milliseconds roughly gives us 60fps
        _tickerSub = Stream.periodic(Duration(milliseconds: 16)).listen((_) {
          state = state.copyWith(
            watchFace: _stopwatchValuesFromDuration(
              DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(_currentRoundModel!.id),
              ),
            ),
            currentLap: state.laps.isEmpty
                ? null
                : _stopwatchValuesFromLatestCheckpoint(DateTime.now()),
          );
        });
      } else {
        _tickerSub?.cancel();
      }
    });
    ref.onDispose(() {
      _tickerSub?.cancel();
    });
    _repository.getLatestTwo().then((box) {
      if (box.noValue || box.value!.isEmpty) {
        state = Stopped();
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
                _totalRunningDuration(box.value!.last!.events),
              ),
              latestEntry: box.value!.length == 2
                  ? _convertModelToHistoryEntry(box.value!.first)
                  : null,
            );
          case Pause():
            state = Paused(
              watchFace: _stopwatchValuesFromDuration(
                _totalRunningDuration(box.value!.last!.events),
              ),
              latestEntry: box.value!.length == 2
                  ? _convertModelToHistoryEntry(box.value!.first)
                  : null,
            );
          case End():
            state = Stopped(
              watchFace: _stopwatchValuesFromDuration(
                _totalRunningDuration(box.value!.last!.events),
              ),
              latestEntry: box.value!.length == 2
                  ? _convertModelToHistoryEntry(box.value!.first)
                  : null,
            );
        }
      }
    });
    return Loading();
  }

  void start() {
    state = Running(
      watchFace: _defaultWatchFace,
      latestEntry: _currentRoundModel != null
          ? _convertModelToHistoryEntry(_currentRoundModel)
          : state.latestEntry,
    );
    _currentRoundModel = RoundModel(_nowStamp);
    _repository.upsert(_currentRoundModel!);
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
    if (state is! Stopped) return;
    final now = DateTime.now();
    state = Running(
      watchFace: state.watchFace,
      latestEntry: state.latestEntry,
      laps: [...state.laps, _stopwatchValuesFromLatestCheckpoint(now)],
    );
    _lastCheckpointTimestamp = now.millisecondsSinceEpoch;
    _updateAndStoreCurrentModel(Resume(_lastCheckpointTimestamp!));
  }

  void recordLap() async {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    //if we allow lap during pause, do not let the user record multiple laps while paused
    if (timestamp == _lastCheckpointTimestamp) return;
    final values = _stopwatchValuesFromLatestCheckpoint(now);
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
    _currentRoundModel = _currentRoundModel!.copyWith(
      copyEvents: [..._currentRoundModel!.events, event],
    );
    _repository.upsert(_currentRoundModel!);
  }

  WatchFace _stopwatchValuesFromLatestCheckpoint(DateTime current) {
    if (_lastCheckpointTimestamp == null) return _defaultWatchFace;
    final duration = current.difference(
      DateTime.fromMillisecondsSinceEpoch(_lastCheckpointTimestamp!),
    );
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

  Duration _totalRunningDuration(List<StopWatchEvent> events) {
    int totalDuration = 0;
    for (final event in events) {
      if (event case Start() || Resume()) {
        totalDuration -= event.timeStamp;
      } else {
        totalDuration += event.timeStamp;
      }
    }
    return Duration(milliseconds: totalDuration);
  }

  WatchFace _stopwatchValuesFromDuration(Duration duration) {
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

  static const _defaultWatchFace = (0, 0, 0, 0, 0, 0);
}
