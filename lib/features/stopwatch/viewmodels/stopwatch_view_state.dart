
import 'package:stopwatch/features/stopwatch/viewmodels/history_entry.dart';

sealed class StopwatchViewState({required final Watchface watchFace, final HistoryEntry? latestEntry, final Watchface? currentLap, final List<Watchface> laps = const []}) {

StopwatchViewState copyWith({
   Watchface? watchFace,
   HistoryEntry? latestEntry,
   Watchface? currentLap,
   List<Watchface>? laps,
   }) {
    return switch (this) {
      StopwatchLoading() => StopwatchLoading(),
      StopwatchRunning(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) => StopwatchRunning(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
         ),
      StopwatchPaused(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) => StopwatchPaused(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
         ),
      StopwatchStopped(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) => StopwatchStopped(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
          ),
     };
   }

}


class StopwatchLoading({Watchface super.watchFace = defaultWatchFace}) extends StopwatchViewState {}
class StopwatchRunning({required Watchface super.watchFace, HistoryEntry? super.latestEntry, Watchface? super.currentLap, List<Watchface> super.laps}) extends StopwatchViewState {}
class StopwatchPaused({ required Watchface super.watchFace, HistoryEntry? super.latestEntry, Watchface? super.currentLap, List<Watchface> super.laps}) extends StopwatchViewState {}
class StopwatchStopped({required Watchface super.watchFace, HistoryEntry? super.latestEntry, Watchface? super.currentLap, List<Watchface> super.laps}) extends StopwatchViewState {}


typedef Watchface = (
  int tenMinutes,
  int minutes,
  int tenSeconds,
  int seconds,
  int hundredsMilliseconds,
  int tensMilliseconds,
);
const defaultWatchFace = (0, 0, 0, 0, 0, 0);