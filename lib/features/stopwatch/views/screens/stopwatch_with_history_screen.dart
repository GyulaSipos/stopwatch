import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/buttons_row.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/dynamic_watchface_digit.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/history_list_item.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/lap_list.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/watchface_separator.dart';

class StopwatchWithHistoryScreen extends ConsumerWidget {
  const StopwatchWithHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstHistoryItem = ref.watch(stopwatchViewModelProvider.select((state) => state.latestEntry));
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        body: CustomScrollView(
          reverse: true,
          slivers: [
            //this is the main stopwatch
            SliverPersistentHeader(
              pinned: true,
              delegate: StopwatchHeaderDelegate(
                minHeight: 160.0, // Watchface + Buttons + Padding
                maxHeight: MediaQuery.of(context).size.height * (firstHistoryItem == null ? 1 : 0.9),
                roundEdges: firstHistoryItem != null,
              ),
            ),

            if (firstHistoryItem != null) SliverToBoxAdapter(child: HistoryListItem(model: firstHistoryItem)),

            //this is the history
            // SliverList(
            //   delegate: SliverChildBuilderDelegate(
            //     (context, index) => Card(
            //       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //       child: ListTile(title: Text("History Item $index")),
            //     ),
            //     childCount: 20,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class StopwatchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final bool roundEdges;

  StopwatchHeaderDelegate({required this.minHeight, required this.maxHeight, required this.roundEdges});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    //progress: 0.0 (full) -> 1.0 (collapsed)
    final double progress = (shrinkOffset / (maxHeight - minHeight)).clamp(0, 1);
    return Builder(
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(roundEdges ? 12 : 0),
              topRight: Radius.circular(roundEdges ? 12 : 0),
            ),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            children: [
              // We use a Padding that reacts to scroll
              Padding(
                padding: EdgeInsets.only(top: lerpDouble(maxHeight * 0.1, 0, progress), bottom: 10),
                //scale them numbers with the screen
                child: FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DynamicWatchfaceDigit((state) => state.watchFace.$1),
                      DynamicWatchfaceDigit((state) => state.watchFace.$2),
                      const WatchfaceSeparator(),
                      DynamicWatchfaceDigit((state) => state.watchFace.$3),
                      DynamicWatchfaceDigit((state) => state.watchFace.$4),
                      const WatchfaceSeparator(),
                      DynamicWatchfaceDigit((state) => state.watchFace.$5),
                      DynamicWatchfaceDigit((state) => state.watchFace.$6),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Opacity(
                  opacity: (1 - progress * 1.5).clamp(0, 1), // Fade out quickly
                  child: LapList(),
                ),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 20, top: 10), child: const ButtonsRow()),
            ],
          ),
        );
      },
    );
  }

  double lerpDouble(double start, double end, double t) => start + (end - start) * t;

  @override
  double get maxExtent => maxHeight;
  @override
  double get minExtent => minHeight;
  @override
  bool shouldRebuild(StopwatchHeaderDelegate oldDelegate) => true;
}
