// Here for future expandability. If business comes up with new requirements.
// For example "allow the user to take notes on their stopwatch events".
// This structure supports those expansions, without being too cumbersome
// now give a strong sense of YAGNI
class RoundModel {
  final List<StopWatchEvent> events;

  RoundModel._(this.events);

  //since only one round can be started at the exact same timeStamp, the start timeStamp is safe to use as id
  String get id =>
      events.firstWhere((event) => event is Start).timeStamp.toString();

  Map<String, dynamic> toJson() => {
    _eventsKey: events.map((event) => event.toJson()).toList(),
  };

  //we want to ensure that every RoundModel has a start, so we only allow instantiation externally with a timestamp
  factory RoundModel(int startTimeStamp) =>
      RoundModel._([Start(startTimeStamp)]);

  factory RoundModel.fromJson(Map<String, dynamic> json) {
    final events = json[_eventsKey];
    if (events is! Iterable<Map<String, dynamic>>) {
      throw ArgumentError('Invalid Roundmodel json');
    }
    return RoundModel._(
      events.map((json) => StopWatchEvent.fromJson(json)).toList(),
    );
  }

  static const _eventsKey = 'events';
}

// Here to give us some nice switches and readable, declarative code when working with stopwatch events
// Inspired by the style of domain modeling freezed popularized in the Flutter word, just without the dependency and code gen
sealed class StopWatchEvent {
  final int timeStamp;

  StopWatchEvent(this.timeStamp);

  // rudamentary serialization implementation to avoid code gen. If model gets more complicated, approach needs reevaluation
  // for now, this can stay, bc public API can only loosen from here (making it Map<String, dynamic>),
  // internal implementation is irrelevant for the rest of the app
  Map<String, int> toMap() => {runtimeType.toString(): timeStamp};

  factory StopWatchEvent.fromMap(Map<String, dynamic> json) {
    if (json.length != 1) {
      throw ArgumentError(
        'Invalid StopWatchEvent json: expected exactly one key',
      );
    }

    final entry = json.entries.first;
    final type = entry.key;
    final timeStamp = entry.value;

    if (timeStamp is! int) {
      throw ArgumentError(
        'Invalid StopWatchEvent json: timestamp must be an int',
      );
    }

    return switch (type) {
      'Start' => Start(timeStamp),
      'Lap' => Lap(timeStamp),
      'Pause' => Pause(timeStamp),
      'Resume' => Resume(timeStamp),
      'End' => End(timeStamp),
      _ => throw ArgumentError('Unknown StopWatchEvent type: $type'),
    };
  }
}

class Start extends StopWatchEvent {
  Start(super.timeStamp);
}

class Lap extends StopWatchEvent {
  Lap(super.timeStamp);
}

class Pause extends StopWatchEvent {
  Pause(super.timeStamp);
}

class Resume extends StopWatchEvent {
  Resume(super.timeStamp);
}

class End extends StopWatchEvent {
  End(super.timeStamp);
}
