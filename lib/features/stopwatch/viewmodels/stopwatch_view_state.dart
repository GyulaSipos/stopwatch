import 'package:stopwatch/features/stopwatch/viewmodels/history_entry.dart';

sealed class StopwatchViewState {
  final Watchface watchFace;
  final HistoryEntry? latestEntry;
  final Watchface? currentLap;
  final List<Watchface> laps;

  StopwatchViewState({required this.watchFace, this.latestEntry, this.currentLap, this.laps = const []});

  StopwatchViewState copyWith({
    Watchface? watchFace,
    HistoryEntry? latestEntry,
    Watchface? currentLap,
    List<Watchface>? laps,
  }) {
    return switch (this) {
      StopwatchLoading() => StopwatchLoading(),
      StopwatchRunning(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) =>
        StopwatchRunning(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
        ),
      StopwatchPaused(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) =>
        StopwatchPaused(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
        ),
      StopwatchStopped(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) =>
        StopwatchStopped(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
        ),
    };
  }
}

class StopwatchLoading extends StopwatchViewState {
  StopwatchLoading({super.watchFace = defaultWatchFace});
}

class StopwatchRunning extends StopwatchViewState {
  StopwatchRunning({required super.watchFace, super.latestEntry, super.currentLap, super.laps});
}

class StopwatchPaused extends StopwatchViewState {
  StopwatchPaused({required super.watchFace, super.latestEntry, super.currentLap, super.laps});
}

class StopwatchStopped extends StopwatchViewState {
  StopwatchStopped({required super.watchFace, super.latestEntry, super.currentLap, super.laps});
}

typedef Watchface = (
  int tenMinutes,
  int minutes,
  int tenSeconds,
  int seconds,
  int hundredsMilliseconds,
  int tensMilliseconds,
);
const defaultWatchFace = (0, 0, 0, 0, 0, 0);


extension WatchfaceComparison on Watchface {
  //useful for tests
  bool isAfter(Watchface other) {
    if ($1 != other.$1) return $1 > other.$1;
    if ($2 != other.$2) return $2 > other.$2;
    if ($3 != other.$3) return $3 > other.$3;
    if ($4 != other.$4) return $4 > other.$4;
    if ($5 != other.$5) return $5 > other.$5;
    return $6 > other.$6;
  }
}
