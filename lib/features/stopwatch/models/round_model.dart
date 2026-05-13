// This class is here for future expandability for when business comes up with new requirements.
// For example "allow the user to take notes on their stopwatch events".
// This structure supports those expansions, without being too cumbersome
// to give a strong sense of YAGNI

class RoundModel {
  final List<StopWatchEvent> events;
  final int id;
  RoundModel._(this.events, this.id);

  //we want to ensure that every RoundModel has a start, so we only allow instantiation externally with a timestamp
  factory RoundModel(int startTimeStamp) =>
      RoundModel._([Start(startTimeStamp)], startTimeStamp);

  Map<String, dynamic> toMap() => {
    eventsKey: events.map((event) => event.toMap()).toList(),
  };

  factory RoundModel.fromMap(Map<String, dynamic> map) {
    final eventsMap = map[eventsKey];
    if (eventsMap is! Iterable<Map<String, dynamic>>) {
      throw ArgumentError('Invalid RoundModel map');
    }
    final events = eventsMap.map((map) => StopWatchEvent.fromMap(map)).toList();
    return RoundModel._(events, events.first._roundModelId);
  }

  RoundModel copyWith({List<StopWatchEvent>? copyEvents}) =>
      RoundModel._(copyEvents ?? events, id);

  static const eventsKey = 'events';
}

// Sealed to give us some nice switches and readable, declarative code when working with stopwatch events
// Inspired by the style of domain modeling freezed popularized in the Flutter word, just without the dependency and code gen
sealed class StopWatchEvent {
  final int timeStamp;
  //we could create RoundModels runtime by iterating over the StopWatchEvents timeStamp ASC, bucketing form start to end.
  //then we wouldn't need this roundModelId.
  //but storage is cheaper than compute and that iterating could take long if someone uses this stopwatch an ungodly amount
  //has no external functionality, so it's better kept private (tradeoff: needs to keep [StopWatchEvent] in this file)
  final int _roundModelId;

  StopWatchEvent(this.timeStamp, this._roundModelId);

  // rudamentary serialization implementation to avoid code gen. If model gets more complicated, approach needs reevaluation
  // for now, this can stay, bc public API can only loosen from here (making it Map<String, dynamic>),
  // internal implementation is irrelevant for the rest of the app
  Map<String, dynamic> toMap() => {
    columnType: runtimeType.toString(),
    columnTimestamp: timeStamp,
    columnRoundModelId: _roundModelId,
  };

  factory StopWatchEvent.fromMap(Map<String, dynamic> map) {
    final timeStamp = map[columnTimestamp];
    if (timeStamp is! int) throw Exception('not a valid timeStamp');
    final roundModelId = map[columnRoundModelId];
    if (roundModelId is! int) throw Exception('not a valid roundModelId');
    final type = map[columnType];
    if (type is! String) throw Exception('not a valid type');
    return switch (type) {
      'Start' => Start(timeStamp),
      'Lap' => Lap(timeStamp, roundModelId),
      'Pause' => Pause(timeStamp, roundModelId),
      'Resume' => Resume(timeStamp, roundModelId),
      'End' => End(timeStamp, roundModelId),
      _ => throw ArgumentError('Unknown StopWatchEvent type: $type'),
    };
  }
}

class Start extends StopWatchEvent {
  Start(int timeStamp) : super(timeStamp, timeStamp);
}

class Lap extends StopWatchEvent {
  Lap(super.timeStamp, super.roundModelId);
}

class Pause extends StopWatchEvent {
  Pause(super.timeStamp, super.roundModelId);
}

class Resume extends StopWatchEvent {
  Resume(super.timeStamp, super.roundModelId);
}

class End extends StopWatchEvent {
  End(super.timeStamp, super.roundModelId);
}

const columnTimestamp = 'time_stamp';
const columnRoundModelId = 'model_id';
const columnType = 'type';
