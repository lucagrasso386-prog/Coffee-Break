import 'dart:math';

import 'game_element.dart';

/// A level's objective, shown on the mission sheet
/// (10-fiche-mission-niveau.md: "la mission et l'élément -- ou les
/// éléments -- ciblé(s)"). Only one mission type exists in the spec so far
/// -- collect a target count of one or more specific elements -- modeled
/// as an enum anyway so a second type can be added later without
/// reshaping this class.
enum MissionType { collectElements }

extension MissionTypeTitle on MissionType {
  /// The mission card's headline text.
  String get title {
    switch (this) {
      case MissionType.collectElements:
        return 'Complète la commande';
    }
  }
}

/// One element this mission needs collected, and how many.
class MissionTarget {
  const MissionTarget({required this.element, required this.count});

  final GameElement element;
  final int count;
}

class LevelMission {
  const LevelMission({required this.type, required this.targets});

  final MissionType type;

  /// 1 or 2 -- per the spec, "peut porter sur plusieurs éléments à la
  /// fois," capped at 2 so it still reads cleanly on the card (the spec's
  /// own "chaque mission doit être conçue pour bien s'adapter visuellement
  /// à la fiche").
  final List<MissionTarget> targets;
}

/// Deterministic per-level mission, seeded by level number so it's stable
/// across rebuilds without needing to persist anything server-side.
class LevelMissionGenerator {
  LevelMissionGenerator._();

  /// The spec's own calibration: level 1 needs 15 individual croissants
  /// (not pairs) for "Complète la commande" to guarantee "ne doit jamais
  /// pouvoir être terminée en moins de 2 minutes." No board-speed or
  /// difficulty-scaling data exists yet (that's board-engine territory,
  /// 11-ecran-de-jeu.md), so every level reuses this same count per
  /// target rather than guessing a curve -- safer to stay at the one
  /// calibrated-safe number than invent a lower one that might undercut
  /// the 2-minute floor.
  static const int countPerTarget = 15;

  static LevelMission forLevel(int levelNumber) {
    // Level 1 reproduces the spec's own worked example exactly (croissant
    // x15, single target) rather than leaving it to the same roll every
    // other level gets.
    if (levelNumber == 1) {
      return const LevelMission(
        type: MissionType.collectElements,
        targets: [MissionTarget(element: GameElement.croissant, count: countPerTarget)],
      );
    }

    final rng = Random(levelNumber * 7919 + 11);
    final elements = GameElement.values.toList()..shuffle(rng);
    final targetCount = rng.nextDouble() < 0.3 ? 2 : 1;
    return LevelMission(
      type: MissionType.collectElements,
      targets: [
        for (final element in elements.take(targetCount))
          MissionTarget(element: element, count: countPerTarget),
      ],
    );
  }
}
