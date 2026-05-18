
import 'package:stopwatch/features/stopwatch/viewmodels/history_view_state.dart';

sealed class StopwatchViewState({required final Watchface watchFace, final HistoryEntry? latestEntry, final Watchface? currentLap, final List<Watchface> laps = const []}) {

StopwatchViewState copyWith({
   Watchface? watchFace,
   HistoryEntry? latestEntry,
   Watchface? currentLap,
   List<Watchface>? laps,
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


class Loading({Watchface super.watchFace = defaultWatchFace}) extends StopwatchViewState {}
class Running({required Watchface super.watchFace, HistoryEntry? super.latestEntry, Watchface? super.currentLap, List<Watchface> super.laps}) extends StopwatchViewState {}
class Paused({ required Watchface super.watchFace, HistoryEntry? super.latestEntry, Watchface? super.currentLap, List<Watchface> super.laps}) extends StopwatchViewState {}
class Stopped({required Watchface super.watchFace, HistoryEntry? super.latestEntry, Watchface? super.currentLap, List<Watchface> super.laps}) extends StopwatchViewState {}


typedef Watchface = (
  int tenMinutes,
  int minutes,
  int tenSeconds,
  int seconds,
  int hundredsMilliseconds,
  int tensMilliseconds,
);
const defaultWatchFace = (0, 0, 0, 0, 0, 0);