// This class is here for future expandability for when business comes up with new requirements.
// For example "allow the user to take notes on their stopwatch events".
// This structure supports those expansions, without being too cumbersome
// to give a strong sense of YAGNI

import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';

class RoundModel {
  final List<StopWatchEvent> events;
  final int id;
  RoundModel._(this.events, this.id);

  //we want to ensure that every RoundModel has a start, so we only allow instantiation externally with a timestamp
  factory RoundModel(int startTimeStamp) =>
      RoundModel._([Start(startTimeStamp)], startTimeStamp);

  Map<String, dynamic> toMap() => {
    eventsKey: events.map((event) => event.toMap(id)).toList(),
  };

  factory RoundModel.fromMap(Map<String, dynamic> map) {
    final eventsMap = map[eventsKey];
    if (eventsMap is! Iterable<Map<String, dynamic>>) {
      throw ArgumentError('Invalid RoundModel map');
    }
    final events = eventsMap.map((map) => StopWatchEvent.fromMap(map)).toList();
    return RoundModel._(events, events.first.timeStamp);
  }

  RoundModel copyWith({List<StopWatchEvent>? copyEvents}) =>
      RoundModel._(copyEvents ?? events, id);

  static const eventsKey = 'events';
}
