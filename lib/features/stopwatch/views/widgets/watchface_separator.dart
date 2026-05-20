import 'package:flutter/material.dart';

class WatchfaceSeparator extends StatelessWidget {
  const WatchfaceSeparator({this.fontSize = 50.0, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    ':',
    style: TextStyle(
      fontSize: fontSize,
      fontFamily: 'Seven Segment', // Prevents layout jitter
      fontFeatures: const [FontFeature.tabularFigures()], // Extra insurance for alignment
    ),
  );
}
