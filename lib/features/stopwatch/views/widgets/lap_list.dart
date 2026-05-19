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
            alignment: .centerRight,
            child: Row(
              mainAxisSize: .min,
              // mainAxisAlignment: .end,
              crossAxisAlignment: .start,
              children: [
                //could trigger a nice staggered exit-right animation
                IconButton(icon: Icon(Icons.clear_all_outlined), onPressed: () => ref.read(stopwatchViewModelProvider.notifier).clearLaps()),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 160),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false, overscroll: false),
                    child: CustomScrollView(
                      slivers: [
                        SliverList.builder(
                          itemCount: laps.length,
                          itemBuilder: (context, index) => Align(
                            alignment: .centerLeft,
                            child: LabeledWatchfaceWidget(
                              label: Text('${laps.length - index}.'),
                              watchFace: laps[index],
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
