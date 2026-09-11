import 'package:flutter/services.dart';

/// The haptic triggers required game-wide, per 07-regles-globales-ui.md.
/// Each method below corresponds to exactly one bullet in that file's
/// "Retour haptique" list -- call the matching one from wherever that event
/// actually happens once the relevant screen exists (none of them do yet;
/// this is ready for `11-ecran-de-jeu.md`, `12-popups-fin-de-niveau.md`,
/// `09-carte-progression.md`, and the nav bar once it's built).
///
/// Built on Flutter's own `HapticFeedback`, so no platform setup is needed
/// beyond what Flutter already provides on iOS and Android.
class HapticsService {
  HapticsService._();

  /// A match resolves successfully.
  static void matchSuccess() => HapticFeedback.lightImpact();

  /// A special piece touches an element and triggers its effect.
  static void specialPieceEffect() => HapticFeedback.mediumImpact();

  /// One tick of the "remaining moves turn into shooting stars" animation
  /// after a win. Call once per star/move converted, not once for the
  /// whole animation.
  static void remainingMoveStar() => HapticFeedback.selectionClick();

  /// Releasing any "Jouer" (Play) button.
  static void playButtonRelease() => HapticFeedback.mediumImpact();

  /// Releasing a level button on the map -- the "buzzer" that physically
  /// depresses like a real buzzer.
  static void levelBuzzerRelease() => HapticFeedback.heavyImpact();

  /// One tick per star during the end-of-level star reveal, and during
  /// play whenever a star-equivalent moment happens (spec lists this as
  /// its own bullet, distinct from the moves-to-stars animation above).
  static void starReveal() => HapticFeedback.selectionClick();

  /// Tapping the bottom navigation bar.
  static void navBarTap() => HapticFeedback.selectionClick();
}
