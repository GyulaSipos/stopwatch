import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

Watchface stopwatchValuesFromDuration(Duration? duration) {
  if (duration == null) return defaultWatchFace;
  final totalMinutes = duration.inMinutes % 60;
  final totalSeconds = duration.inSeconds % 60;
  final totalMilliseconds = duration.inMilliseconds % 1000;
  return (
    totalMinutes ~/ 10,
    totalMinutes % 10,
    totalSeconds ~/ 10,
    totalSeconds % 10,
    totalMilliseconds ~/ 100,
    (totalMilliseconds ~/ 10) % 10,
  );
}
