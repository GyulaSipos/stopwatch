import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/labeled_watchface_widget.dart';

class LapList extends ConsumerWidget {
  const LapList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laps = ref.watch(stopwatchViewModelProvider.select((state) => state.laps.reversed.toList()));
    return CustomScrollView(
      slivers: [
        SliverList.builder(
          itemCount: laps.length,
          itemBuilder: (context, index) => LabeledWatchfaceWidget(label: Text('${laps.length - index }.'), watchFace: laps[index]),
        ),
      ],
    );
  }
}
