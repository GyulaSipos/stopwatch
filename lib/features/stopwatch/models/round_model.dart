// This class is here for future expandability for when business comes up with new requirements.
// For example "allow the user to take notes on their stopwatch events".
// This structure supports those expansions, without being too cumbersome
// to give a strong sense of YAGNI

import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';

class RoundModel {
  final List<StopWatchEvent> events;
  final int id;
  final int? totalRunningDuration;

  RoundModel._(this.events, this.id, this.totalRunningDuration);

  //we want to ensure that every RoundModel has a start, so we only allow instantiation externally with a timestamp
  factory RoundModel(int startTimeStamp, {int? totalRunningDuration}) =>
      RoundModel._([Start(startTimeStamp)], startTimeStamp, totalRunningDuration);

  Map<String, dynamic> toMap() => {
    'id': id,
    eventsKey: events.map((event) => event.toMap(id)).toList(),
    totalRunningDurationKey: totalRunningDuration,
  };

  factory RoundModel.fromMap(Map<String, dynamic> map) {
    final eventsMap = map[eventsKey];
    if (eventsMap is! Iterable) {
      throw ArgumentError('Invalid RoundModel map');
    }
    final events = eventsMap.map((map) => StopWatchEvent.fromMap(map)).toList();
    final id = map['id'];
    final totalRunningDuration = map[totalRunningDurationKey] as int?;
    return RoundModel._(events, id, totalRunningDuration);
  }

  RoundModel copyWith({List<StopWatchEvent>? copyEvents, int? totalRunningDuration}) =>
      RoundModel._(copyEvents ?? events, id, totalRunningDuration ?? this.totalRunningDuration);

  static const eventsKey = 'events';
  static const totalRunningDurationKey = 'totalRunningDuration';

  @override
  bool operator ==(Object other) => other is RoundModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
