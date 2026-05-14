import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';

class DynamicWatchfaceDigit extends ConsumerWidget {
  final int Function(StopwatchViewState) selector;
  final double fontSize;

  const DynamicWatchfaceDigit(this.selector, {this.fontSize = 50.0, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digit = ref.watch(stopwatchViewModelProvider.select((state) => selector(state)));
    return Text(
      '$digit',
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'monospace', // Prevents layout jitter
        fontFeatures: const [FontFeature.tabularFigures()], // Extra insurance for alignment
      ),
    );
  }
}
