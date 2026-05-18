import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';

Duration calculateTotalRunningDuration(List<StopWatchEvent> events) => _calculateDuration(events, false);

Duration calculateRunningDurationSinceLastLap(List<StopWatchEvent> events) => _calculateDuration(events, true);

Duration _calculateDuration(List<StopWatchEvent> events, bool fromLastLap) {
  final index = events.lastIndexWhere((event) => event is Lap || event is Start);
  bool wasWatchStoppedInThePreviousLap = index == 0 || events.elementAtOrNull(index - 1) is Pause;
  final isRunning =
      events.last is Start || events.last is Resume || (events.last is Lap && !wasWatchStoppedInThePreviousLap);
  //opening the ledger in a way the starting Laps condition (clock was running or not) is counted
  int totalDuration = !fromLastLap || wasWatchStoppedInThePreviousLap ? 0 : 0 - events[index].timeStamp;
  for (final event in [
    ...fromLastLap ? events.sublist(index) : events,
    //need to close the ledger at now if timet otherwise is running
    if (isRunning) End(DateTime.now().millisecondsSinceEpoch),
  ]) {
    if (event case Start() || Resume()) {
      totalDuration -= event.timeStamp;
    } else if (event case Pause() || End()) {
      totalDuration += event.timeStamp;
    }
  }
  return Duration(milliseconds: totalDuration);
}
