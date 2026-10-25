import 'package:flutter/material.dart';

/// Root widget. Theme and the tab shell arrive in later tasks (T02, T19).
class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(),
    );
  }
}
