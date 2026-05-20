import 'package:flutter/material.dart';
import 'package:stopwatch/features/stopwatch/viewmodels/stopwatch_view_state.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/static_watchface_digit.dart';
import 'package:stopwatch/features/stopwatch/views/widgets/watchface_separator.dart';

///Please only use this for static watchfaces, as its not performant to rebuild everything in the frequency of a running one
class LabeledWatchfaceWidget extends StatelessWidget {
  const LabeledWatchfaceWidget({super.key, required this.label, required this.watchFace, this.fontSize = 25.0});

  final Widget label;
  final Watchface watchFace;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: .min,
      mainAxisAlignment: .end,
      children: [
        label,
        Padding(padding: EdgeInsetsGeometry.only(right: 24)),
        StaticWatchfaceDigit(watchFace.$1, fontSize: fontSize),
        StaticWatchfaceDigit(watchFace.$2, fontSize: fontSize),
        WatchfaceSeparator(fontSize: fontSize),
        StaticWatchfaceDigit(watchFace.$3, fontSize: fontSize),
        StaticWatchfaceDigit(watchFace.$4, fontSize: fontSize),
        WatchfaceSeparator(fontSize: fontSize),
        StaticWatchfaceDigit(watchFace.$5, fontSize: fontSize),
        StaticWatchfaceDigit(watchFace.$6, fontSize: fontSize),
      ],
    );
  }
}
