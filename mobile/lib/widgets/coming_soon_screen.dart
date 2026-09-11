import 'package:flutter/material.dart';

/// Stand-in destination for any button whose real screen isn't built yet
/// (its spec file hasn't been reached). Deliberately minimal -- there's
/// nothing to build ahead of that file.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Break')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
