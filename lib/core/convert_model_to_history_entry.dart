import 'package:stopwatch/core/runtime_calculations.dart';
import 'package:stopwatch/core/stopwatch_values_from_duration.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_view_state.dart';

HistoryEntry? convertModelToHistoryEntry(RoundModel? model) {
  if (model == null || model.totalRunningDuration == null) return null;
  return HistoryEntry(
    totalTimeRow: (
      DateTime.fromMillisecondsSinceEpoch(model.events.first.timeStamp),
      stopwatchValuesFromDuration(Duration(milliseconds: model.totalRunningDuration!)),
    ),
    laps: calculateLapDurations(
      model.events,
    ).map((duration) => stopwatchValuesFromDuration(duration)).toList(),
  );
}
