import 'package:stopwatch/core/app_exception.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_entry.dart';

sealed class HistoryViewState {
  final List<HistoryEntry> history;
  HistoryViewState({required this.history});
}

class HistoryLoading extends HistoryViewState {
  HistoryLoading({super.history = const <HistoryEntry>[]});
}

class HistoryLoaded extends HistoryViewState {
  HistoryLoaded({required super.history});
}

class HistoryError extends HistoryViewState {
  final AppException exception;
  HistoryError({
    super.history = const <HistoryEntry>[],
    required this.exception,
  });
}
