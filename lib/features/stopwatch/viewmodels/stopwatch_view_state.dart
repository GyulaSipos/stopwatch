

sealed class StopwatchViewState({final StopwatchValues? values, final HistoryEntry? latestEntry, final List<StopwatchValues> laps = const []}) {

StopwatchViewState copyWith({
    StopwatchValues? values,
    HistoryEntry? latestEntry,
    List<StopwatchValues>? laps,
  }) {
    return switch (this) {
      Loading() => Loading(),
      Running(values: final v, latestEntry: final le, laps: final l) => Running(
          values: values ?? v,
          latestEntry: latestEntry ?? le,
          laps: laps ?? l,
        ),
      Paused(values: final v, latestEntry: final le, laps: final l) => Paused(
          values: values ?? v,
          latestEntry: latestEntry ?? le,
          laps: laps ?? l,
        ),
      Stopped(values: final v, latestEntry: final le, laps: final l) => Stopped(
          values: values ?? v,
          latestEntry: latestEntry ?? le,
          laps: laps ?? l,
        ),
    };
  }

}


class Loading extends StopwatchViewState {}
class Running({required super.values, super.latestEntry, super.laps}) extends StopwatchViewState {}
class Paused({ required super.values, super.latestEntry, super.laps}) extends StopwatchViewState {}
class Stopped({ super.values, super.latestEntry, super.laps}) extends StopwatchViewState {}


typedef StopwatchValues = (
  int tenMinutes,
  int minutes,
  int tenSeconds,
  int seconds,
  int hundredsMilliseconds,
  int tensMilliseconds,
);

typedef HistoryEntry = (DateTime start, StopwatchValues values);