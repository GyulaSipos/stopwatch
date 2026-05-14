
sealed class StopwatchViewState({final WatchFace? watchFace, final HistoryEntry? latestEntry, final WatchFace? currentLap, final List<WatchFace> laps = const []}) {

StopwatchViewState copyWith({
   WatchFace? watchFace,
   HistoryEntry? latestEntry,
   WatchFace? currentLap,
   List<WatchFace>? laps,
   }) {
    return switch (this) {
      Loading() => Loading(),
      Running(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) => Running(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
         ),
      Paused(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) => Paused(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
         ),
      Stopped(watchFace: final v, latestEntry: final le, currentLap: final cl, laps: final l) => Stopped(
          watchFace: watchFace ?? v,
          latestEntry: latestEntry ?? le,
          currentLap: currentLap ?? cl,
          laps: laps ?? l,
          ),
     };
   }

}


class Loading extends StopwatchViewState {}
class Running({required super.watchFace, super.latestEntry, super.currentLap, super.laps}) extends StopwatchViewState {}
class Paused({ required super.watchFace, super.latestEntry, super.currentLap, super.laps}) extends StopwatchViewState {}
class Stopped({ super.watchFace, super.latestEntry, super.currentLap, super.laps}) extends StopwatchViewState {}


typedef WatchFace = (
  int tenMinutes,
  int minutes,
  int tenSeconds,
  int seconds,
  int hundredsMilliseconds,
  int tensMilliseconds,
);

typedef HistoryEntry = (DateTime start, WatchFace values);