import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// One of the 8 loading-screen background variants from
/// 07-regles-globales-ui.md. Each asset already has the thin darker seam
/// baked in at its vertical center (the source photos didn't have one --
/// added per that file's dev note, so the panel reads as hinged/opening in
/// its middle instead of as one flat image cut in half).
enum LoadingBackground {
  variant1,
  variant2,
  variant3,
  variant4,
  variant5,
  variant6,
  variant7,
  variant8;

  String get assetName =>
      'assets/loading_backgrounds/chargement-fond-${index + 1}.jpg';

  static LoadingBackground random() =>
      values[Random().nextInt(values.length)];
}

/// The loading-screen transition required for every loading page in the
/// game *except* the very first one at app launch (that one's covered by
/// `08-page-accueil.md`, not this). Splits into a top and bottom half that
/// slide in from off-screen and meet at the center; reverses the same way
/// to dismiss. Total time on screen -- both animations plus whatever
/// [future] takes -- is capped at 2 seconds, per spec ("durée d'affichage :
/// 2 secondes maximum"): if [future] hasn't resolved by then, the overlay
/// dismisses anyway and reveals [builder]'s content regardless.
///
/// Not wired into any navigation flow yet -- there's no screen to navigate
/// *to* until `08-page-accueil.md` onward exist. This is ready for whoever
/// builds the first real screen transition to use.
class LoadingTransitionOverlay extends StatefulWidget {
  const LoadingTransitionOverlay({
    super.key,
    required this.future,
    required this.builder,
    this.background,
  });

  /// The work to do while the panel is closed (e.g. precaching images,
  /// warming some state [builder]'s content reads independently -- this
  /// doesn't feed a result into [builder] itself). The overlay dismisses
  /// once this completes, or at the 2-second cap, whichever comes first.
  /// A [future] that throws is treated the same as one that never resolves
  /// -- the overlay still dismisses at the cap; inspect the outcome
  /// separately if the caller needs to react to failure.
  final Future<void> future;

  /// Builds the content revealed once the panel opens.
  final WidgetBuilder builder;

  final LoadingBackground? background;

  @override
  State<LoadingTransitionOverlay> createState() =>
      _LoadingTransitionOverlayState();
}

enum _Phase { closing, closed, opening, open }

class _LoadingTransitionOverlayState extends State<LoadingTransitionOverlay>
    with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(milliseconds: 350);
  static const _totalCap = Duration(milliseconds: 2000);

  late final LoadingBackground _background;
  late final AnimationController _controller;
  _Phase _phase = _Phase.closing;

  @override
  void initState() {
    super.initState();
    _background = widget.background ?? LoadingBackground.random();
    _controller = AnimationController(vsync: this, duration: _slideDuration);
    _runSequence();
  }

  Future<void> _runSequence() async {
    final stopwatch = Stopwatch()..start();

    // Close (slide the two halves together).
    await _controller.forward();
    if (!mounted) return;
    setState(() => _phase = _Phase.closed);

    // Hold closed until the real work finishes, capped so the total time
    // on screen -- both slides plus the hold -- never exceeds `_totalCap`.
    final remainingBudget = _totalCap - (_slideDuration * 2) - stopwatch.elapsed;
    final capFuture = remainingBudget > Duration.zero
        ? Future<void>.delayed(remainingBudget)
        : Future<void>.value();
    // A failing `future` shouldn't crash the transition -- it dismisses at
    // the cap either way, same as one that just never resolves.
    final safeFuture = widget.future.then((_) {}, onError: (_) {});
    await Future.any([safeFuture, capFuture]);
    if (!mounted) return;

    // Open (slide the two halves back apart).
    setState(() => _phase = _Phase.opening);
    await _controller.reverse();
    if (!mounted) return;
    setState(() => _phase = _Phase.open);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revealed = Builder(builder: widget.builder);
    if (_phase == _Phase.open) return revealed;

    return Stack(
      fit: StackFit.expand,
      children: [
        revealed,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final halfHeight = constraints.maxHeight / 2;
                final offset = (1 - _controller.value) * halfHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _half(top: true, offset: -offset, size: constraints.biggest),
                    _half(top: false, offset: offset, size: constraints.biggest),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// A half-screen window (the top or bottom half, via [Positioned] with an
  /// explicit height -- NOT `Align`'s `heightFactor`, which is silently
  /// ignored here since the parent `Stack` imposes tight constraints on it)
  /// showing the matching half of the full background image, offset by the
  /// slide animation.
  Widget _half({required bool top, required double offset, required Size size}) {
    final halfHeight = size.height / 2;
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: halfHeight,
      child: ClipRect(
        child: Align(
          alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(0, offset),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Image.asset(_background.assetName, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
