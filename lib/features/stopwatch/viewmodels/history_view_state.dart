import 'package:stopwatch/core/app_exception.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_entry.dart';

sealed class HistoryViewState({required final List<HistoryEntry> history}) {}

class HistoryLoading({ List<HistoryEntry> super.history = const <HistoryEntry>[]}) extends HistoryViewState {}
class HistoryLoaded({required  List<HistoryEntry> super.history}) extends HistoryViewState {}
class HistoryError({ List<HistoryEntry> super.history = const <HistoryEntry>[], required AppException exception}) extends HistoryViewState {}

