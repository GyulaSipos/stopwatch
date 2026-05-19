import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/buttons_row.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/dynamic_watchface_digit.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/history_list.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/history_list_item.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/lap_list.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/watchface_separator.dart';

class StopwatchScreen extends ConsumerStatefulWidget {
  const StopwatchScreen({super.key});

  @override
  ConsumerState<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends ConsumerState<StopwatchScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _userHasScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_listenToScroll);
  }

  void _listenToScroll() {
    //once the user scrolls even a tiny bit, mount the rest of the list
    if (_scrollController.offset > 5 && !_userHasScrolled) {
      setState(() {
        _userHasScrolled = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstHistoryItem = ref.watch(stopwatchViewModelProvider.select((state) => state.latestEntry));

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        body: CustomScrollView(
          controller: _scrollController, // Attach the controller here
          reverse: true,
          //since scroll triggers history, we need the view to be scrollable, even on tall screens,
          //where the entire firstHistoryEntry is on the screen at the same time.
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), // Allows dragging past edges
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: StopwatchHeaderDelegate(
                minHeight: 160.0,
                maxHeight: MediaQuery.of(context).size.height * (firstHistoryItem == null ? 1 : 0.9),
                roundEdges: firstHistoryItem != null,
              ),
            ),
            if (firstHistoryItem != null)
              SliverToBoxAdapter(
                child: HistoryListItem(model: firstHistoryItem, key: ValueKey(firstHistoryItem.totalTimeRow)),
              ),

            //only inject into the widget tree if the user has actually scrolled
            if (firstHistoryItem != null && _userHasScrolled) const HistoryList(),
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
