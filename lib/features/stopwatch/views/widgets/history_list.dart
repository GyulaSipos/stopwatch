import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_view_model.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_view_state.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/history_list_item.dart';

class HistoryList extends ConsumerWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyViewModelProvider);
    return switch (state) {
      //a shimmery loading list would be more pleasing, but this project takes too much time as it is, so just imageine,
      //we have shimmers here
      HistoryLoading() => SliverFillRemaining(child: Center(child: CircularProgressIndicator.adaptive())),
      //imagine a better error screen here with user friendly messages for all AppExceptions
      HistoryError() => SliverFillRemaining(child: Center(child: Text('Error happened'))),
      HistoryLoaded(:final history) =>
        history.isEmpty
            ? SliverFillRemaining(
                child: Center(child: Text("That's all folks")),
              ) //of course a more professional message is needed here
            : SliverList.builder(
                itemCount: history.length,
                itemBuilder: (context, index) =>
                    HistoryListItem(model: history[index], key: ValueKey(history[index].totalTimeRow)),
              ),
    };
  }
}
