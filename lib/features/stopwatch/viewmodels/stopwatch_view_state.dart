sealed class StopwatchViewState({final HistoryEntry? latestEntry, final List<StopwatchValues> laps = const []}) {

}

class Loading extends StopwatchViewState {}
class Stopped({super.latestEntry, super.laps}) extends StopwatchViewState {}
class Running(final StopwatchValues values, {super.latestEntry, super.laps})  extends StopwatchViewState {}
class Paused(final StopwatchValues values, {super.latestEntry, super.laps}) extends StopwatchViewState {}


typedef StopwatchValues = (
  int tenMinutes,
  int minutes,
  int tenSeconds,
  int seconds,
  int hundredsMilliseconds,
  int tensMilliseconds,
);

typedef HistoryEntry = (DateTime start, StopwatchValues values);