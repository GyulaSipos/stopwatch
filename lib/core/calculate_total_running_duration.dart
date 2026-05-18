import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';

Duration calculateTotalRunningDuration(List<StopWatchEvent> events, {bool isCurrentlyRunning = false}) {
  int totalDuration = 0;
  for (final event in [...events, if (isCurrentlyRunning) End(DateTime.now().millisecondsSinceEpoch)]) {
    if (event case Start() || Resume()) {
      totalDuration -= event.timeStamp;
    } else if (event case Pause() || End()) {
      totalDuration += event.timeStamp;
    }
  }
  return Duration(milliseconds: totalDuration);
}
