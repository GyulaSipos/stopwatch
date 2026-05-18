import 'package:stopwatch/core/stopwatch_values_from_duration.dart';
import 'package:stopwatch/core/total_running_duration_since_last_lap_or_start.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_view_state.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

HistoryEntry? convertModelToHistoryEntry(RoundModel? model) {
  if (model == null || model.totalRunningDuration == null) return null;
  return HistoryEntry(
    totalTimeRow: (
      DateTime.fromMillisecondsSinceEpoch(model.events.first.timeStamp),
      stopwatchValuesFromDuration(Duration(milliseconds: model.totalRunningDuration!)),
    ),
    //if there is no lap, do not add the End event as lap
    laps: model.events.any((event) => event is Lap)
        ? model.events.indexed
              .map((indexed) {
                if (indexed.$2 case Lap() || End()) {
                  return stopwatchValuesFromDuration(
                    totalRunningDurationSinceLastLapOrStart(model.events.sublist(0, indexed.$1 + 1)),
                  );
                } else {
                  return null;
                }
              })
              .whereType<Watchface>()
              .toList()
        : [],
  );
}
