import 'package:flutter/material.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_view_state.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/labeled_watchface_widget.dart';

class HistoryListItem extends StatelessWidget {
  const HistoryListItem({required this.model, super.key});

  final HistoryEntry model;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: .end,
              mainAxisSize: .min,
              children: [
                FittedBox(
                  child: LabeledWatchfaceWidget(
                    label: Text(model.totalTimeRow.$1.toIso8601String()),
                    watchFace: model.totalTimeRow.$2,
                  ),
                ),
                ...model.laps.indexed.map(
                  (indexed) => FittedBox(
                    child: LabeledWatchfaceWidget(
                      label: Text('${indexed.$1 + 1}.'),
                      watchFace: indexed.$2,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
