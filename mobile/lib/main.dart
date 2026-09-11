import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const CoffeeBreakApp());
}

class CoffeeBreakApp extends StatelessWidget {
  const CoffeeBreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Break',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
