import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/dynamic_watchface_digit.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/lap_list.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/watchface_separator.dart';

class StopwatchScreen extends ConsumerWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        fit: .expand,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: .min,
            children: [
              Row(
                mainAxisAlignment: .center,
                mainAxisSize: .min,
                crossAxisAlignment: .center,
                children: [
                  DynamicWatchfaceDigit((state) => state.watchFace.$1),
                  DynamicWatchfaceDigit((state) => state.watchFace.$2),
                  WatchfaceSeparator(),
                  DynamicWatchfaceDigit((state) => state.watchFace.$3),
                  DynamicWatchfaceDigit((state) => state.watchFace.$4),
                  WatchfaceSeparator(),
                  DynamicWatchfaceDigit((state) => state.watchFace.$5),
                  DynamicWatchfaceDigit((state) => state.watchFace.$6),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints.loose(Size(MediaQuery.sizeOf(context).width / 1.5, 300)),
                child: LapList())
            ],
          ),
          Positioned(
            bottom: 20,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => ref.read(stopwatchViewModelProvider.notifier).start(),
                  icon: Icon(Icons.play_arrow_outlined),
                ),
                IconButton(
                  onPressed: () => ref.read(stopwatchViewModelProvider.notifier).pause(),
                  icon: Icon(Icons.pause_circle_filled_outlined),
                ),
                IconButton(
                  onPressed: () => ref.read(stopwatchViewModelProvider.notifier).resume(),
                  icon: Icon(Icons.play_circle_fill),
                ),
                IconButton(
                  onPressed: () => ref.read(stopwatchViewModelProvider.notifier).end(),
                  icon: Icon(Icons.stop),
                ),
                IconButton(
                  onPressed: () => ref.read(stopwatchViewModelProvider.notifier).recordLap(),
                  icon: Icon(Icons.circle_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
