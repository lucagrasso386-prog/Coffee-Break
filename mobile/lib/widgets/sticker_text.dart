import 'package:flutter/material.dart';

/// Bold fill text with a white sticker-style outline, used for every big
/// title in this game's UI ("Niveau N" on the mission sheet, "PERDU" /
/// "GAGNÉ" on the end-of-level popups). Stacks 8 offset white copies of
/// the text behind the real (colored) one rather than using a
/// stroke-style `Paint`, which doesn't blend cleanly with a separate
/// fill pass at these font sizes.
class StickerText extends StatelessWidget {
  const StickerText(
    this.text, {
    super.key,
    required this.color,
    this.fontSize = 28,
    this.outlineWidth = 1.5,
  });

  final String text;
  final Color color;
  final double fontSize;
  final double outlineWidth;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: 1);
    final w = outlineWidth;
    final offsets = [
      Offset(-w, -w), Offset(w, -w), Offset(-w, w), Offset(w, w),
      Offset(-w, 0), Offset(w, 0), Offset(0, -w), Offset(0, w),
    ];
    return Stack(
      children: [
        for (final o in offsets)
          Transform.translate(
            offset: o,
            child: Text(text, style: style.copyWith(color: Colors.white)),
          ),
        Text(text, style: style.copyWith(color: color)),
      ],
    );
  }
}
