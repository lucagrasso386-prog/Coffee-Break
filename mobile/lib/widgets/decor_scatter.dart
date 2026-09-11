import 'dart:math';

import '../models/decor_variant.dart';

class ScatteredDecor {
  const ScatteredDecor({
    required this.variant,
    required this.angle,
    required this.side,
    required this.scale,
    required this.flipped,
  });

  final DecorVariant variant;

  /// This piece's fixed position on the drum, same convention as a level
  /// node's angle (see `CylinderProjection`).
  final double angle;

  /// Lateral offset from the path center, roughly -1..1 (negative = left).
  final double side;

  /// Extra scale on top of the variant's own `baseScale`.
  final double scale;
  final bool flipped;
}

/// Deterministic scatter of decor along the path, so the same stretch of
/// map always looks the same across rebuilds (no re-rolling every frame)
/// while still reading as hand-placed rather than one motif repeating.
///
/// Each "filler" slot independently rolls whether anything sits there and,
/// if so, which pool variant -- so consecutive slots don't line up into an
/// obvious pattern. Landmarks (e.g. the Coffee Bar) use a separate,
/// guaranteed spacing instead of a roll, since they're waypoints, not
/// background dressing. Both pools start empty until decor art exists;
/// registering variants is the only wiring needed once it does.
class DecorScatter {
  const DecorScatter({
    required this.fillerPool,
    required this.landmarkPool,
    this.slotSpacing = 0.15,
    this.fillerChance = 0.35,
    this.landmarkEveryLevels = 10,
    this.anglePerLevel = 0.42,
  });

  final List<DecorVariant> fillerPool;
  final List<DecorVariant> landmarkPool;

  /// Angular spacing between filler slots -- denser than levels, since
  /// decor is meant to feel more continuous than the level path itself.
  final double slotSpacing;

  /// Chance any given filler slot actually places something.
  final double fillerChance;

  final int landmarkEveryLevels;
  final double anglePerLevel;

  List<ScatteredDecor> forRange(double minAngle, double maxAngle) {
    final result = <ScatteredDecor>[];

    if (fillerPool.isNotEmpty) {
      final firstSlot = (minAngle / slotSpacing).floor();
      final lastSlot = (maxAngle / slotSpacing).ceil();
      for (var slot = firstSlot; slot <= lastSlot; slot++) {
        // Seeded by the slot's own index -- stable across rebuilds, and
        // independent of neighboring slots so the pattern doesn't repeat.
        final rng = Random(slot * 7919 + 13);
        if (rng.nextDouble() > fillerChance) continue;
        final variant = fillerPool[rng.nextInt(fillerPool.length)];
        result.add(ScatteredDecor(
          variant: variant,
          angle: slot * slotSpacing + (rng.nextDouble() - 0.5) * slotSpacing * 0.6,
          side: (rng.nextBool() ? -1 : 1) * (0.55 + rng.nextDouble() * 0.35),
          scale: variant.baseScale * (0.85 + rng.nextDouble() * 0.3),
          flipped: rng.nextBool(),
        ));
      }
    }

    if (landmarkPool.isNotEmpty) {
      final landmarkSpacing = anglePerLevel * landmarkEveryLevels;
      final firstMark = (minAngle / landmarkSpacing).floor();
      final lastMark = (maxAngle / landmarkSpacing).ceil();
      for (var m = firstMark; m <= lastMark; m++) {
        final rng = Random(m * 104729 + 5);
        final variant = landmarkPool[rng.nextInt(landmarkPool.length)];
        result.add(ScatteredDecor(
          variant: variant,
          angle: m * landmarkSpacing,
          side: rng.nextBool() ? -0.9 : 0.9,
          scale: variant.baseScale,
          flipped: rng.nextBool(),
        ));
      }
    }

    return result;
  }
}
