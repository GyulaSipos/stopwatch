import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_model.dart';

class LatestLap extends ConsumerWidget {
  const LatestLap({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lapCount = ref.watch(stopwatchViewModelProvider.select((state) => state.laps.length + 1));


    return Container();
  }
}
