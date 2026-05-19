import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

class HistoryEntry {
  final (DateTime start, Watchface values) totalTimeRow;
  final List<Watchface> laps;

  HistoryEntry({required this.totalTimeRow, required this.laps});

  @override
  bool operator ==(Object other) =>
      //we dont need to fully check everything to be sure things are not the same
      other is HistoryEntry &&
      other.totalTimeRow.$1.isAtSameMomentAs(totalTimeRow.$1) &&
      laps.length == other.laps.length;

  @override
  int get hashCode => totalTimeRow.hashCode;
}
