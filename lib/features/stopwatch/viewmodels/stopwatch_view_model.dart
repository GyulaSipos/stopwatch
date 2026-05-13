import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/repositories/stopwatch_repository.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

final stopwatchViewModelProvider = Provider(
  (ref) => StopwatchViewModel(ref.watch(stopwatchRepositoryProvider)),
);

class StopwatchViewModel extends Notifier<StopwatchViewState> {
  final IStopwatchRepository repository;
  int? _lastCheckpointTimestamp;

  StopwatchViewModel(this.repository);

  @override
  StopwatchViewState build() {
    listenSelf((_, next) {
      if (next case Running() || Resume()) {
        //TODO: implement ticker behavior
      }
    });
    repository.getLatestTwo().then((box) {
      if (box.noValue || box.value!.isEmpty) {
        state = Stopped();
      } else {
        //we made sure to always get the events in timestamp ASC
        switch (box.value!.last!.events.last) {
          case Start(:final timeStamp):
          case Resume(:final timeStamp):
          case Lap(:final timeStamp):
            _lastCheckpointTimestamp = timeStamp;
            state = Running(
              _stopwatchValuesFromDuration(
                _totalRunningDuration(box.value!.last!.events),
              ),
              latestEntry: box.value!.length == 2
                  ? _convertModelToHistoryEntry(box.value!.first)
                  : null,
            );
          case Pause():
            state = Paused(
              _stopwatchValuesFromDuration(
                _totalRunningDuration(box.value!.last!.events),
              ),
              latestEntry: box.value!.length == 2
                  ? _convertModelToHistoryEntry(box.value!.first)
                  : null,
            );
          case End():
            state = Stopped(
              latestEntry: box.value!.length == 2
                  ? _convertModelToHistoryEntry(box.value!.first)
                  : null,
            );
        }
      }
    });
    return Loading();
  }

  StopwatchValues _stopwatchValuesFromLatestCheckpoint() {
    if (_lastCheckpointTimestamp == null) return (0, 0, 0, 0, 0, 0);
    final duration = DateTime.now().difference(
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

  StopwatchValues _stopwatchValuesFromDuration(Duration duration) {
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
