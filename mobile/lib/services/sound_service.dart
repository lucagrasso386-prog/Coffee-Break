import 'package:flutter/foundation.dart';

/// Every button and every animation needs a matching sound effect, per
/// 07-regles-globales-ui.md ("Règle ferme"). No audio files exist yet and
/// no music is planned for now (per the same file), so this is a stub:
/// [play] is a no-op that only logs in debug mode, so call sites can be
/// wired up ahead of the actual assets without anything breaking. Swap
/// the no-op body for a real audio player (e.g. `audioplayers` or
/// `just_audio`, neither added to pubspec.yaml yet) once sound files
/// exist, without needing to touch any call site.
class SoundService {
  SoundService._();

  static void play(SoundEffect effect) {
    if (kDebugMode) {
      debugPrint('SoundService: would play "${effect.name}" (no audio file wired up yet)');
    }
  }
}

/// One entry per distinct sound the game needs. Add to this as screens are
/// built and call out specific sounds -- this only lists the ones implied
/// by 07-regles-globales-ui.md itself; it's not meant to be exhaustive.
enum SoundEffect {
  buttonTap,
  matchSuccess,
  specialPieceEffect,
  remainingMoveStar,
  playButtonRelease,
  levelBuzzerRelease,
  starReveal,
  navBarTap,
  loadingScreenAppear,
  loadingScreenDismiss,
}
