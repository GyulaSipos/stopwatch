import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/features/stopwatch/views/screens/stopwatch_screen.dart';
import 'package:stopwatch/core/theme.dart';

void main() {
  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: MaterialTheme().lightMediumContrast(),
      darkTheme: MaterialTheme().darkMediumContrast(),
      home: StopwatchScreen(),
    );
  }
}
