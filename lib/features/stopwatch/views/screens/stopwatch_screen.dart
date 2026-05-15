import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/buttons_row.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/dynamic_watchface_digit.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/lap_list.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/watchface_separator.dart';

class StopwatchScreen extends ConsumerWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () {
          final state = ref.read(stopwatchViewModelProvider);
          state is Running
              ? ref.read(stopwatchViewModelProvider.notifier).pause()
              : state is Paused
              ? ref.read(stopwatchViewModelProvider.notifier).resume()
              : ref.read(stopwatchViewModelProvider.notifier).start();
        },
        const SingleActivator(LogicalKeyboardKey.keyL): () {
          ref.read(stopwatchViewModelProvider.notifier).recordLap();
        },
        const SingleActivator(LogicalKeyboardKey.keyS): () {
          ref.read(stopwatchViewModelProvider.notifier).end();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            fit: .expand,
            alignment: Alignment.center,
            children: [
              Center(
                child: Column(
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
                      constraints: BoxConstraints(minHeight: 0, maxHeight: MediaQuery.sizeOf(context).width / 1.5),
                      child: LapList(),
                    ),
                  ],
                ),
              ),
              Positioned(bottom: 20, child: ButtonsRow()),
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(onPressed: () {}, icon: Icon(Icons.history)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
