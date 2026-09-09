/// One decor asset the progression map can scatter along the path
/// (09-carte-progression.md). The creator is sending several variants per
/// kind of decor (several palm trees, several flowers, ...) precisely so
/// the map doesn't read as one motif copy-pasted -- see
/// `widgets/decor_scatter.dart` for how a pool of these gets placed.
enum DecorCategory {
  /// Scattered freely along the path -- palm trees, flowers, clouds.
  filler,

  /// A sparser, guaranteed waypoint rather than random filler -- the
  /// "Coffee Bar" building and anything else meant to read as a landmark
  /// rather than background dressing.
  landmark,
}

class DecorVariant {
  const DecorVariant({
    required this.assetName,
    required this.category,
    this.baseScale = 1,
  });

  final String assetName;
  final DecorCategory category;

  /// Relative size multiplier before the scatter's own per-instance
  /// randomization -- lets one variant (e.g. a small flower cluster vs. a
  /// tall palm tree) be scaled differently from the rest of its pool.
  final double baseScale;
}
