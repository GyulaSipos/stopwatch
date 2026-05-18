import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';

Duration calculateTotalRunningDuration(List<StopWatchEvent> events) => _calculateDuration(events, false);

Duration calculateRunningDurationSinceLastLap(List<StopWatchEvent> events) => _calculateDuration(events, true);

Duration _calculateDuration(List<StopWatchEvent> events, bool fromLastLap) {
  if (events.isEmpty) return Duration.zero;

  //normalize the list for the ledger
  final hasEnd = events.last is End;
  final endTime = hasEnd ? events.last.timeStamp : DateTime.now().millisecondsSinceEpoch;
  final baseEvents = hasEnd ? events.sublist(0, events.length - 1) : events;

  if (baseEvents.isEmpty) return Duration.zero;

  final index = baseEvents.lastIndexWhere((event) => event is Lap || event is Start);
  if (index == -1) return Duration.zero;

  bool wasWatchStoppedInThePreviousLap = index == 0 || baseEvents.elementAtOrNull(index - 1) is Pause;

  final isRunning =
      baseEvents.last is Start ||
      baseEvents.last is Resume ||
      (baseEvents.last is Lap && !wasWatchStoppedInThePreviousLap);

  //run the ledger
  int totalDuration = !fromLastLap || wasWatchStoppedInThePreviousLap ? 0 : 0 - baseEvents[index].timeStamp;

  for (final event in [
    ...fromLastLap ? baseEvents.sublist(index) : baseEvents,
    //close the ledger using the designated endTime if it was still running
    if (isRunning) End(endTime),
  ]) {
    if (event case Start() || Resume()) {
      totalDuration -= event.timeStamp;
    } else if (event case Pause() || End()) {
      totalDuration += event.timeStamp;
    }
  }

  return Duration(milliseconds: totalDuration);
}

List<Duration> calculateLapDurations(List<StopWatchEvent> events) {
  //early returns if nothing to do
  if (events.isEmpty) return [];
  if (!events.any((event) => event is Lap)) return [];

  final List<Duration> lapDurations = [];

  int lastEventTime = events.first.timeStamp;
  bool isRunning = true; //timeline always starts with a 'Start' event
  int currentLapAccumulator = 0;

  for (int i = 1; i < events.length; i++) {
    final event = events[i];
    final int delta = event.timeStamp - lastEventTime;
    if (isRunning) {
      currentLapAccumulator += delta;
    }
    if (event is Pause) {
      isRunning = false;
    } else if (event is Resume) {
      isRunning = true;
    } else if (event is Lap || event is End) {
      lapDurations.add(Duration(milliseconds: currentLapAccumulator));
      currentLapAccumulator = 0; //reset for the next lap segment
    }

    lastEventTime = event.timeStamp;
  }

  //if the round was not ended yet
  if (events.last is! End && isRunning) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    currentLapAccumulator += (now - lastEventTime);
    lapDurations.add(Duration(milliseconds: currentLapAccumulator));
  }

  return lapDurations;
}
