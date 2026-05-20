import 'package:stopwatch/core/app_exception.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_entry.dart';

sealed class HistoryViewState({required final List<HistoryEntry> history}) {}

class HistoryLoading({ super.history = const <HistoryEntry>[]}) extends HistoryViewState {}
class HistoryLoaded({required super.history}) extends HistoryViewState {}
class HistoryError({ super.history = const <HistoryEntry>[], required AppException exception}) extends HistoryViewState {}

