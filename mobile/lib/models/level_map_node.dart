/// 09-carte-progression.md: one level button on the progression map.
///
/// Only two visual states exist per the spec -- "non validé" (matte, no
/// effect, no star) and "validé" (glow + 1-3 stars) -- there's no separate
/// "locked" look, since the player has access to the first 10 000 levels
/// from the very first launch.
enum LevelButtonColor { purple, blue, pink, lightBlue }

class LevelMapNode {
  const LevelMapNode({
    required this.number,
    required this.validated,
    required this.stars,
    required this.color,
  });

  /// 1-based level number.
  final int number;
  final bool validated;

  /// 0-3. Only meaningful when [validated].
  final int stars;

  /// Purely cosmetic per the spec ("purement esthétiques, sans logique de
  /// statut") -- not tied to level difficulty, biome, or anything else.
  final LevelButtonColor color;
}

class LevelMapGenerator {
  LevelMapGenerator._();

  /// "Le joueur a accès aux 10 000 premiers niveaux" -- the other 9000 are
  /// meant to be generated/loaded on demand as the player scrolls that far,
  /// which -- like the day/night cycle and the biome change every 10
  /// levels -- is deferred (see mobile/README.md).
  static const int preloadedCount = 1000;

  /// Builds the preloaded window. [unlockedLevel] marks every level up to
  /// and including it as validated -- the real per-level star history
  /// (1-3 stars per completed level) isn't tracked server-side yet
  /// (`ProgressDTO` only carries a single `unlockedLevel`), so every
  /// validated level shows a placeholder full 3 stars until that exists.
  static List<LevelMapNode> generatePreloaded({required int unlockedLevel}) {
    return List.generate(preloadedCount, (i) {
      final number = i + 1;
      final validated = number <= unlockedLevel;
      return LevelMapNode(
        number: number,
        validated: validated,
        stars: validated ? 3 : 0,
        color: LevelButtonColor.values[i % LevelButtonColor.values.length],
      );
    });
  }
}
