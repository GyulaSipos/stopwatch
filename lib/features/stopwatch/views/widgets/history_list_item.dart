import 'package:flutter/material.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/labeled_watchface_widget.dart';

class HistoryListItem extends StatelessWidget {
  const HistoryListItem({required this.model, super.key});

  final RoundModel model;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrinats) {
        return Card(
          child: Column(
            mainAxisSize: .min,
            children: [
              FittedBox(child: LabeledWatchfaceWidget(label: label, watchFace: watchFace),)

            ],
          ),
        );
      }
    );
  }
}
