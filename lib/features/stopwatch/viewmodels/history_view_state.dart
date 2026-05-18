


import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

class HistoryEntry {
  final (DateTime start, Watchface values) totalTimeRow;
  final List<Watchface> laps;

  HistoryEntry({required this.totalTimeRow, required this.laps});
}