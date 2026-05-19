// Sealed to give us some nice switches and readable, declarative code when working with stopwatch events
// Inspired by the style of domain modeling freezed popularized in the Flutter word, just without the dependency and code gen
sealed class StopWatchEvent {
  final int timeStamp;

  StopWatchEvent(this.timeStamp);

  // rudamentary serialization implementation to avoid code gen. If model gets more complicated, approach needs reevaluation
  // for now, this can stay, bc public API can only loosen from here (making it Map<String, dynamic>),
  // internal implementation is irrelevant for the rest of the app
  Map<String, dynamic> toMap(int roundModelId) => {
    columnType: runtimeType.toString(),
    columnTimestamp: timeStamp,
    columnRoundModelId: roundModelId,
  };

  factory StopWatchEvent.fromMap(Map<String, dynamic> map) {
    final timeStamp = map[columnTimestamp];
    if (timeStamp is! int) throw Exception('not a valid timeStamp');
    final type = map[columnType];
    if (type is! String) throw Exception('not a valid type');
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

class Start(super.timeStamp) extends StopWatchEvent {}

class Lap(super.timeStamp) extends StopWatchEvent {}

class Pause(super.timeStamp) extends StopWatchEvent {}

class Resume(super.timeStamp) extends StopWatchEvent {}

class End(super.timeStamp) extends StopWatchEvent {}

const columnTimestamp = 'time_stamp';
const columnRoundModelId = 'model_id';
const columnType = 'type';
