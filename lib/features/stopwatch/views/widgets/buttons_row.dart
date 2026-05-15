import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

class ButtonsRow extends ConsumerStatefulWidget {
  const ButtonsRow({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ButtonsRowState();
}

class _ButtonsRowState extends ConsumerState<ButtonsRow> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stopwatchViewModelProvider);
    return SizedBox(
      width: MediaQuery.sizeOf(context).width - 24,
      child: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: state is! Paused
                ? const SizedBox.shrink() // Becomes size 0
                : Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () => ref.read(stopwatchViewModelProvider.notifier).end(),
                      child: const Icon(Icons.stop),
                    ),
                  ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: ElevatedButton(
              onPressed: () => state is Running
                  ? ref.read(stopwatchViewModelProvider.notifier).pause()
                  : state is Paused
                  ? ref.read(stopwatchViewModelProvider.notifier).resume()
                  : ref.read(stopwatchViewModelProvider.notifier).start(),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 250),
                child: state is Running ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: state is Stopped
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      onPressed: () => ref.read(stopwatchViewModelProvider.notifier).recordLap(),
                      child: Transform.flip(flipX: true, child: const Icon(Icons.refresh)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
