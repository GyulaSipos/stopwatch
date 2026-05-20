import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/labeled_watchface_widget.dart';

class LapList extends ConsumerWidget {
  const LapList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laps = ref.watch(stopwatchViewModelProvider.select((state) => state.laps.reversed.toList()));
    return laps.isEmpty
        ? SizedBox.shrink()
        : Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //could trigger a nice staggered exit-right animation
                IconButton(
                  icon: const Icon(Icons.clear_all_outlined),
                  onPressed: () => ref.read(stopwatchViewModelProvider.notifier).clearLaps(),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false, overscroll: false),
                    child: CustomScrollView(
                      slivers: [
                        SliverList.builder(
                          itemCount: laps.length,
                          itemBuilder: (context, index) => Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: LabeledWatchfaceWidget(
                                label: Text(
                                  '${laps.length - index}.',
                                  style: const TextStyle(
                                    fontFamily: 'Seven Segment', // Prevents layout jitter
                                    fontFeatures: [FontFeature.tabularFigures()], // Extra insurance for alignment
                                  ),
                                ),
                                watchFace: laps[index],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
