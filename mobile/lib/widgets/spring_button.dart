import 'package:flutter/material.dart';

/// Wraps [child] with the press animation required by every button in the
/// game, per 07-regles-globales-ui.md: scales down on press, springs back
/// on release. Use this instead of a bare `GestureDetector`/`InkWell` for
/// any tappable control -- "tous les boutons du jeu, sans exception."
///
/// Does not itself play a sound or haptic; wire those in [onPressed]
/// (see `services/haptics_service.dart`, `services/sound_service.dart`)
/// since which one applies depends on what the button does.
class SpringButton extends StatefulWidget {
  const SpringButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.pressedScale = 0.92,
  });

  final Widget child;
  final VoidCallback onPressed;

  /// How much the button shrinks while held down.
  final double pressedScale;

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  static const _pressDuration = Duration(milliseconds: 80);
  // Overshoots past 1.0 before settling, for the "spring" feel on release.
  static const _releaseDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _pressDuration);
    // No fixed CurvedAnimation wrapper here -- the curve is passed directly
    // to animateTo/animateBack below so press and release can each use a
    // different one (a plain ease-out going down, an elastic overshoot
    // coming back up) without the two curves compounding on each other.
    _scale = Tween(begin: 1.0, end: widget.pressedScale).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.animateTo(1, duration: _pressDuration, curve: Curves.easeOut);
  }

  void _onTapUp(TapUpDetails _) => _release();
  void _onTapCancel() => _release();

  void _release() {
    _controller.animateBack(0, duration: _releaseDuration, curve: Curves.elasticOut);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
