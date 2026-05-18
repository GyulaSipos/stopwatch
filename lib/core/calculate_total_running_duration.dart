import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';

Duration calculateTotalRunningDuration(List<StopWatchEvent> events) {
  final index = events.lastIndexWhere((event) => event is Lap || event is Start);
  bool wasWatchStoppedInThePreviousLap = index == 0 || events.elementAtOrNull(index - 1) is Pause;
  final isRunning =
      events.last is Start || events.last is Resume || (events.last is Lap && !wasWatchStoppedInThePreviousLap);
  int totalDuration = 0;
  for (final event in [...events, if (isRunning) End(DateTime.now().millisecondsSinceEpoch)]) {
    if (event case Start() || Resume()) {
      totalDuration -= event.timeStamp;
    } else if (event case Pause() || End()) {
      totalDuration += event.timeStamp;
    }
  }
  return Duration(milliseconds: totalDuration);
}
