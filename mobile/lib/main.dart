import 'package:flutter/material.dart';

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
      // Placeholder root screen — real screens start with
      // 08-page-accueil.md. This just proves the app boots.
      home: const Scaffold(
        body: Center(child: Text('Coffee Break')),
      ),
    );
  }
}
