import 'package:flutter/material.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/history_entry.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/labeled_watchface_widget.dart';

class HistoryListItem extends StatelessWidget {
  const HistoryListItem({required this.model, super.key});

  final HistoryEntry model;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
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
                    //here we could create a much nicer display of the time that displays the minimal info necessary
                    //like: yesterday, 3 days ago, jun 13, 2025. dec. 31
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
