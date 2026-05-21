# Stopwatch

The aim for this project is to give the users a durable, fault tolerant, performant stopwatch for their time measuring needs.

## Setup:

Use flutter >= 3.44.0 (or fvm)

If primary constructors are not stable yet, you need these run args too:

```
         "--enable-experiment=primary-constructors",
         "--extra-front-end-options=--enable-experiment=primary-constructors"
```

## Architecture:

The project uses an MVVM-like layered approach, driven by Riverpod state management
and backed by a minimal Sqflite persistence layer.

### Package Structure

```
  lib/
  ├── main.dart                          <-- MaterialApp + StopwatchScreen
  ├── core/
  │     ├── box.dart                     <-- Box<T> error wrapper
  │     ├── app_exception.dart           <-- Ex: AppExceptionNotFound
  │     ├── runtime_calculations.dart    <-- Duration math
  │     ├── stopwatch_values_from_duration.dart
  │     ├── convert_model_to_history_entry.dart
  │     └── theme.dart                  <-- MaterialTheme
  └── features/stopwatch/
        ├── models/
        │     ├── round_model.dart       <-- Event-sourced round aggregate
        │     └── stopwatch_event.dart   <-- Sealed: Start, Lap, Pause, Resume, End
        ├── repositories/
        │     └── stopwatch_repository.dart  <-- IStopwatchRepository + StopwatchRepository
        ├── viewmodels/
        │     ├── stopwatch_view_model.dart       <-- StopwatchViewModel (Notifier)
        │     ├── stopwatch_view_state.dart        <-- Loading / Running / Paused / Stopped
        │     ├── history_view_model.dart
        │     ├── history_view_state.dart
        │     └── history_entry.dart
        ├── services/
        │     └── round_model_local_data_source.dart  <-- SQFLite persistence
        └── views/
              ├── screens/stopwatch_screen.dart
              └── widgets/
                    ├── buttons_row.dart
                    ├── dynamic_watchface_digit.dart
                    ├── static_watchface_digit.dart
                    ├── watchface_separator.dart
                    ├── labeled_watchface_widget.dart
                    ├── lap_list.dart
                    ├── history_list.dart
                    └── history_list_item.dart
```

### Data Flow

```
  User Tap
      │
      ▼
  StopwatchViewModel.start() / pause() / resume() / recordLap() / end()
      │
      ▼
  State Transition → Notifier updates state
      │
      ├──► Ref.watch() listeners →  UI rebuild
      │
      └──►  _updateAndStoreCurrentModel()
              │
              ▼
          StopwatchRepository.upsert(RoundModel)
              │
              ▼
          SQFLite transaction
              ├──▶ round_model table
              └──▶ stopwatch_event table
              │
              ▼
          Box<T> result
              │
              ▼
  UI re-renders on the next ticker (16 ms / 60 fps)
```

### State Machine

```
  [Loading]
      │
      ▼
  [Running] <==========[Paused]
      │                    │
      │ pause()            │ resume()
      ▼                    │
  [Stopped] <==============+
      │
   (irreversible final state)
```

### Key Design Decisions

| Concern          | Choice                  | Rationale                                       |
| ---------------- | ----------------------- | ----------------------------------------------- |
| State Management | Riverpod Notifier       | easy testing, also acts as DI container         |
| State Modeling   | Sealed Classes          | Exhaustive `switch`, no hidden branches       |
| Event Sourcing   | RoundModel.events       | extensible event schema                         |
| Persistence      | SQFLite                 | Offline-first, zero ORM baggage, ACID compliant |
| Error Handling   | Box\<T\> result wrapper | Explicit error paths, no try/catch              |
