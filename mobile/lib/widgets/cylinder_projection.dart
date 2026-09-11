import 'dart:math' as math;

/// The perspective math behind 09-carte-progression.md's scroll: "surface
/// courbe (cylindre/boule) qui tourne au swipe vertical ... les éléments en
/// retrait se rapprochent et grossissent en perspective en tournant,
/// jusqu'à sortir du cadre." Chosen over the spec's own simpler fallback
/// (2D distortion shader + parallax) per the creator's call for real 3D
/// curvature now rather than later.
///
/// Every level node and decor piece sits at a fixed angle on an invisible
/// drum whose axis points at the camera. Scrolling changes [rotation];
/// projecting an item's angle against the current rotation gives where it
/// lands on screen, how big it is, and how visible it is.
///
/// The constants here are a reasoned starting point, not a measured one --
/// this couldn't be visually tuned against the real art or on a device from
/// this environment. Expect to adjust `radius`/`focalLength` once someone
/// can actually run the app and see the curve.
class CylinderProjection {
  const CylinderProjection({
    this.radius = 900,
    this.focalLength = 700,
    this.verticalStretch = 1.35,
    this.fadeStartRadians = 1.15,
    this.fadeEndRadians = 1.45,
  });

  final double radius;
  final double focalLength;
  final double verticalStretch;

  /// Beyond this angle (ahead of the camera, heading toward the horizon)
  /// a node starts fading rather than popping out of view abruptly.
  final double fadeStartRadians;

  /// Angle at which a node is fully faded (and should stop being built).
  final double fadeEndRadians;

  /// [angle] is the node's fixed position on the drum, in radians (0 =
  /// closest to the camera). [rotation] is the current scroll state
  /// (grows as the player scrolls toward higher levels). [baseY] is the
  /// screen Y of the theta=0 point (where the closest node sits).
  CylinderPoint project({
    required double angle,
    required double rotation,
    required double baseY,
  }) {
    final theta = angle - rotation;
    if (theta >= 0) {
      // Ahead of the camera: the node rolls up and away, shrinking toward
      // the horizon -- true cylinder projection.
      final depth = radius * (1 - math.cos(theta));
      final rise = radius * math.sin(theta);
      final scale = focalLength / (focalLength + depth);
      final dy = baseY - rise * scale * verticalStretch;
      return CylinderPoint(
        dy: dy,
        scale: scale,
        opacity: _opacityFor(theta),
      );
    }
    // Already passed the camera: rather than mirror the same shrink (which
    // would visually read as the node shrinking *toward* the viewer,
    // wrong), it keeps walking past at full scale and exits below --
    // matching the "walked past the camera" reading of a node the player
    // has already scrolled beyond. Slope matches the curve's own
    // derivative at theta=0 so the motion stays continuous through it.
    final dy = baseY - radius * verticalStretch * theta;
    return CylinderPoint(dy: dy, scale: 1, opacity: _opacityFor(theta));
  }

  double _opacityFor(double theta) {
    final a = theta.abs();
    if (a <= fadeStartRadians) return 1;
    if (a >= fadeEndRadians) return 0;
    return 1 - (a - fadeStartRadians) / (fadeEndRadians - fadeStartRadians);
  }
}

class CylinderPoint {
  const CylinderPoint({
    required this.dy,
    required this.scale,
    required this.opacity,
  });

  final double dy;
  final double scale;
  final double opacity;

  bool get isVisible => opacity > 0.01;
}
