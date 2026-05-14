import 'package:flutter/material.dart';

class StaticWatchfaceDigit extends StatelessWidget {
  final int digit;
  final double fontSize;

  const StaticWatchfaceDigit(this.digit, {this.fontSize = 50.0, super.key});

  @override
  Widget build(BuildContext context) {
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
