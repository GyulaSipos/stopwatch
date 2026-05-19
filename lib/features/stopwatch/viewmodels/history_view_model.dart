import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/core/convert_model_to_history_entry.dart';
import 'package:stopwatch/features/stopwatch/repositories/stopwatch_repository.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_entry.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_view_state.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';

final historyViewModelProvider = NotifierProvider<HistoryViewModel, HistoryViewState>(HistoryViewModel.new);

class HistoryViewModel extends Notifier<HistoryViewState> {
  @override
  HistoryViewState build() {
    final firstHistoryEntry = ref.watch(stopwatchViewModelProvider.select((swState) => swState.latestEntry));
    ref.read(stopwatchRepositoryProvider).getAllHistory().then((box) {
      if (box.hasException) {
        state = HistoryError(exception: box.exception!);
      } else if (box.value == null || box.value!.isEmpty) {
        state = HistoryLoaded(history: []);
      } else {
        var list = List<HistoryEntry>.from(box.$1!.map((model) => convertModelToHistoryEntry(model)!));
        //remove the already present entry(s) from the list
        if (list.first == firstHistoryEntry) {
          list.removeAt(0);
        } else if (list.length > 1 && list[1] == firstHistoryEntry) {
          list.removeRange(0, 2);
        }
        state = HistoryLoaded(history: list);
      }
    });
    return HistoryLoading();
  }
}
