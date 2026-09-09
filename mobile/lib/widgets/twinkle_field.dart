import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// 09-carte-progression.md's night sky: "poussière d'étoiles visible."
/// The creator's own addition on top of that -- a moon and 2 different
/// star shapes, small, glowing, each appearing and disappearing on its
/// own random cycle rather than all at once. Purely decorative, fills
/// whatever area it's given (the screen positions it over the sky).
class TwinkleField extends StatefulWidget {
  const TwinkleField({super.key, required this.assets, this.count = 10});

  /// Sprite variants (already cut out, transparent background) to
  /// scatter -- cycled across instances, not one-per-slot.
  final List<String> assets;
  final int count;

  @override
  State<TwinkleField> createState() => _TwinkleFieldState();
}

class _TwinkleFieldState extends State<TwinkleField> {
  late final List<_TwinkleSpec> _specs;

  @override
  void initState() {
    super.initState();
    // Fixed seed: a stable scatter (positions/timings don't reshuffle on
    // every rebuild), still reads as random since nothing here lines up
    // with the grid-based decor elsewhere on the map.
    final rng = math.Random(42);
    _specs = List.generate(widget.count, (i) {
      return _TwinkleSpec(
        asset: widget.assets[rng.nextInt(widget.assets.length)],
        left: rng.nextDouble(),
        top: rng.nextDouble(),
        size: 16 + rng.nextDouble() * 18,
        period: Duration(milliseconds: 2600 + rng.nextInt(3200)),
        delay: Duration(milliseconds: rng.nextInt(6000)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              for (final spec in _specs)
                Positioned(
                  left: spec.left * constraints.maxWidth - spec.size * 1.2,
                  top: spec.top * constraints.maxHeight - spec.size * 1.2,
                  child: _Twinkle(spec: spec),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TwinkleSpec {
  const _TwinkleSpec({
    required this.asset,
    required this.left,
    required this.top,
    required this.size,
    required this.period,
    required this.delay,
  });

  final String asset;
  final double left;
  final double top;
  final double size;
  final Duration period;
  final Duration delay;
}

class _Twinkle extends StatefulWidget {
  const _Twinkle({required this.spec});

  final _TwinkleSpec spec;

  @override
  State<_Twinkle> createState() => _TwinkleState();
}

class _TwinkleState extends State<_Twinkle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.spec.period);
    // Fade in, hold briefly, fade out, hold off -- not a plain sine
    // pulse, so it reads as "appears, then disappears" rather than a
    // continuous glow.
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
    ]).animate(_controller);
    Future.delayed(widget.spec.delay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.spec.size;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(opacity: _opacity.value, child: child),
      child: SizedBox(
        width: size * 2.4,
        height: size * 2.4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft glow: the same sprite, tinted flat white and blurred,
            // so it reads as a halo matching the shape rather than a
            // generic circular bloom.
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: size * 0.35, sigmaY: size * 0.35),
              child: Image.asset(
                widget.spec.asset,
                width: size * 1.5,
                height: size * 1.5,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
            Image.asset(widget.spec.asset, width: size, height: size),
          ],
        ),
      ),
    );
  }
}
