import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/cloud_schedule.dart';
import '../models/currency.dart';
import '../models/day_night_period.dart';
import '../models/decor_variant.dart';
import '../models/level_map_node.dart';
import '../networking/api_client.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/cylinder_projection.dart';
import '../widgets/decor_scatter.dart';
import '../widgets/spring_button.dart';
import '../widgets/twinkle_field.dart';

/// 09-carte-progression.md: the level map. Most decor art (palm trees,
/// hibiscus, plumeria, the "Coffee Bar" building, clouds) isn't in yet --
/// this is the scroll mechanism and level-node behavior on placeholder
/// shapes, to be re-skinned once those assets arrive. The sky, sand path,
/// and grass ground (all three lighting variants, all three of them) are
/// in and already wired.
///
/// Deliberately deferred for this pass, same as earlier files' pattern of
/// modeling a not-yet-buildable system as data/behavior first: the
/// day/night cycle, the biome change every 10 levels, and infinite level
/// generation past the first 1000 preloaded (see `LevelMapGenerator`).
class ProgressionMapScreen extends StatefulWidget {
  const ProgressionMapScreen({super.key});

  @override
  State<ProgressionMapScreen> createState() => _ProgressionMapScreenState();
}

class _ProgressionMapScreenState extends State<ProgressionMapScreen>
    with SingleTickerProviderStateMixin {
  static const double _anglePerLevel = 0.42;
  static const double _dragPixelsPerRadian = 220;
  static const CylinderProjection _projection = CylinderProjection();

  // See the `sceneItems` comment in build(): keeps a shadow's sort key
  // just under its owner's so it always draws immediately behind it.
  static const double _shadowSortEpsilon = 0.0001;

  /// Filler decor. Unlike the level buttons (one asset set reused as-is
  /// for both periods), the creator sends a genuinely distinct render per
  /// period for each piece -- same pose each time, but a different color
  /// grade -- so day/golden-hour/night each get their own asset rather
  /// than sharing one.
  static const List<DecorVariant> _fillerDay = [
    DecorVariant(
      assetName: 'assets/progression_map/frangipanier_day.png',
      category: DecorCategory.filler,
      baseScale: 1.2,
    ),
    DecorVariant(
      assetName: 'assets/progression_map/palmier_day.png',
      category: DecorCategory.filler,
      baseScale: 1.3,
    ),
  ];
  static const List<DecorVariant> _fillerGolden = [
    DecorVariant(
      assetName: 'assets/progression_map/frangipanier_golden.png',
      category: DecorCategory.filler,
      baseScale: 1.2,
    ),
    DecorVariant(
      assetName: 'assets/progression_map/palmier_golden.png',
      category: DecorCategory.filler,
      baseScale: 1.3,
    ),
  ];
  static const List<DecorVariant> _fillerNight = [
    DecorVariant(
      assetName: 'assets/progression_map/frangipanier_night.png',
      category: DecorCategory.filler,
      baseScale: 1.2,
    ),
    DecorVariant(
      assetName: 'assets/progression_map/palmier_night.png',
      category: DecorCategory.filler,
      baseScale: 1.3,
    ),
  ];
  static const Map<DayNightPeriod, List<DecorVariant>> _fillerPoolByPeriod = {
    DayNightPeriod.day: _fillerDay,
    DayNightPeriod.goldenHour: _fillerGolden,
    DayNightPeriod.night: _fillerNight,
  };

  /// Landmark pool (the Coffee Bar building) stays empty until that art
  /// exists -- registering a variant here is the only wiring
  /// `DecorScatter` needs to start placing it (see mobile/README.md,
  /// 09-carte-progression.md section).
  late final DecorScatter _decorScatter;

  late final AnimationController _flingController;
  double _rotation = 0;
  List<LevelMapNode> _nodes =
      LevelMapGenerator.generatePreloaded(unlockedLevel: 0);
  ProgressDTO? _progress;
  ui.Image? _pathTexture;
  ui.Image? _grassPlain;
  ui.Image? _grassTuft;
  late final String _skyAsset;
  late final DayNightPeriod _period;
  late final int _cloudCount;
  late final List<String> _cloudAssets;

  static const Map<DayNightPeriod, String> _skyByPeriod = {
    DayNightPeriod.day: 'assets/progression_map/sky_day.jpg',
    DayNightPeriod.goldenHour: 'assets/progression_map/sky_golden.jpg',
    DayNightPeriod.night: 'assets/progression_map/sky_night.jpg',
  };

  // "Poussière d'étoiles visible" (spec) plus the creator's own moon/star
  // twinkle sprites -- night sky only, so this only ever loads its assets
  // once the sky is already the night variant.
  static const List<String> _twinkleAssets = [
    'assets/progression_map/twinkle_moon.png',
    'assets/progression_map/twinkle_star_big.png',
    'assets/progression_map/twinkle_star_small.png',
  ];

  // Per the creator ("pas de nuage la nuit"): no clouds at night at all --
  // the twinkle field owns the night sky instead. `_cloudCount` is forced
  // to 0 for that period in initState, so night has no entry here.
  static const Map<DayNightPeriod, List<String>> _cloudAssetsByPeriod = {
    DayNightPeriod.day: [
      'assets/progression_map/cloud_1_day.png',
      'assets/progression_map/cloud_2_day.png',
    ],
    DayNightPeriod.goldenHour: [
      'assets/progression_map/cloud_1_golden.png',
      'assets/progression_map/cloud_2_golden.png',
    ],
  };

  // 3 fixed positions (fraction of the sky area) rather than a random
  // scatter -- there are only ever 2 or 3 clouds on screen, few enough
  // that a deliberate placement reads better than a seeded-random one.
  // Cycles through `_cloudAssets` by index, not one variant per slot.
  static const List<_CloudSlot> _cloudSlots = [
    _CloudSlot(left: 0.12, top: 0.08, width: 0.42),
    _CloudSlot(left: 0.58, top: 0.04, width: 0.36),
    _CloudSlot(left: 0.36, top: 0.20, width: 0.30),
  ];

  double get _minRotation => 0;
  double get _maxRotation => (_nodes.length - 1) * _anglePerLevel;

  // `num.clamp` returns `num`, not `double`/`int` -- these avoid that
  // footgun (an assignment-time type error) via dart:math's generic
  // min/max, which preserve the operand type instead of widening it.
  double _clampRotation(double v) =>
      math.max(_minRotation, math.min(_maxRotation, v));

  int _clampIndex(int v) => math.max(0, math.min(_nodes.length - 1, v));

  @override
  void initState() {
    super.initState();
    // Fixed once per screen instance, same reasoning as HomeScreen's own
    // background pick -- not re-evaluated on every rebuild.
    _period = DayNightSchedule.current();
    _skyAsset = _skyByPeriod[_period]!;
    _cloudCount = _period == DayNightPeriod.night ? 0 : CloudSchedule.countFor();
    _cloudAssets = _cloudAssetsByPeriod[_period] ?? const [];
    _decorScatter = DecorScatter(
      fillerPool: _fillerPoolByPeriod[_period] ?? const [],
      landmarkPool: const [],
      anglePerLevel: _anglePerLevel,
    );
    _flingController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _rotation = _clampRotation(_flingController.value);
        });
      });
    _loadProgress();
    _loadPathTexture();
    _loadGrassTextures();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await ApiClient.shared.fetchProgress();
      if (progress != null && mounted) {
        setState(() {
          _progress = progress;
          _nodes = LevelMapGenerator.generatePreloaded(
            unlockedLevel: progress.unlockedLevel,
          );
        });
      }
    } catch (_) {
      // Offline, backend unreachable, or no session yet -- stay with the
      // "nothing validated" default rather than blocking the map.
    }
  }

  static const Map<DayNightPeriod, String> _pathTextureByPeriod = {
    DayNightPeriod.day: 'assets/progression_map/sand_path_day.jpg',
    DayNightPeriod.goldenHour: 'assets/progression_map/sand_path_golden.jpg',
    DayNightPeriod.night: 'assets/progression_map/sand_path_night.jpg',
  };

  Future<void> _loadPathTexture() async {
    final asset = _pathTextureByPeriod[DayNightSchedule.current()]!;
    final image = await _loadImage(asset);
    if (image == null) return;
    setState(() => _pathTexture = image);
  }

  // Ground fill: the creator's source photo is one green field with a
  // handful of grass tufts scattered on it. Tiling that whole image would
  // repeat the exact same tuft cluster in a visible grid, so it's split
  // into two pieces here instead -- a tuft-free strip tiled seamlessly
  // (via ImageShader, same mirroring trick as the sand path) as the
  // continuous base, and the tufts (feathered to transparent at the edges
  // so stamping them leaves no visible square edge) scattered sparsely on
  // top by `_GrassPainter`, per the creator's own "sometimes just green,
  // sometimes green with a tuft" direction.
  //
  static const Map<DayNightPeriod, String> _grassPlainByPeriod = {
    DayNightPeriod.day: 'assets/progression_map/grass_plain_day.jpg',
    DayNightPeriod.goldenHour: 'assets/progression_map/grass_plain_golden.jpg',
    DayNightPeriod.night: 'assets/progression_map/grass_plain_night.jpg',
  };
  static const Map<DayNightPeriod, String> _grassTuftByPeriod = {
    DayNightPeriod.day: 'assets/progression_map/grass_tuft_day.png',
    DayNightPeriod.goldenHour: 'assets/progression_map/grass_tuft_golden.png',
    DayNightPeriod.night: 'assets/progression_map/grass_tuft_night.png',
  };

  Future<void> _loadGrassTextures() async {
    final period = DayNightSchedule.current();
    final plain = await _loadImage(_grassPlainByPeriod[period]!);
    final tuft = await _loadImage(_grassTuftByPeriod[period]!);
    if (plain == null || tuft == null) return;
    setState(() {
      _grassPlain = plain;
      _grassTuft = tuft;
    });
  }

  Future<ui.Image?> _loadImage(String asset) async {
    final bytes = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return null;
    }
    return frame.image;
  }

  @override
  void dispose() {
    _flingController.dispose();
    _pathTexture?.dispose();
    _grassPlain?.dispose();
    _grassTuft?.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _flingController.stop();
    setState(() {
      _rotation = _clampRotation(_rotation - details.delta.dy / _dragPixelsPerRadian);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = -details.velocity.pixelsPerSecond.dy / _dragPixelsPerRadian;
    _flingController.animateWith(FrictionSimulation(0.12, _rotation, velocity));
  }

  void _openLevel(LevelMapNode node) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComingSoonScreen(
        message: 'Le niveau ${node.number} arrive avec 11-ecran-de-jeu.md.',
      ),
    ));
  }

  void _openStub(String message) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ComingSoonScreen(message: message)));
  }

  /// A soft ellipse at an item's foot -- the cheap trick that sells
  /// "resting on the curved surface" rather than "pasted on top of it".
  /// Uses the same `point` (scale + opacity) the item itself was
  /// projected with, so the shadow shrinks and fades in lockstep as the
  /// item rolls away over the drum, instead of floating at a fixed size.
  /// A flat radial gradient stands in for a blurred one -- visually close
  /// enough at this size, and cheap even with a dozen-plus on screen at
  /// once (an `ImageFiltered` blur per shadow would add up).
  Widget _contactShadow({
    required CylinderPoint point,
    required double centerX,
    required double footY,
    required double baseWidth,
  }) {
    final width = baseWidth * point.scale;
    final height = width * 0.32;
    return Positioned(
      top: footY - height / 2,
      left: centerX - width / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: point.opacity * 0.55,
          child: Container(
            width: width,
            height: height,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              gradient: RadialGradient(
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final baseY = height * 0.88;

          final centerIndex = (_rotation / _anglePerLevel).round();
          const window = 6;
          final start = _clampIndex(centerIndex - window);
          final end = _clampIndex(centerIndex + window);

          final visible = <_ProjectedNode>[];
          for (var i = start; i <= end; i++) {
            final angle = i * _anglePerLevel;
            final point =
                _projection.project(angle: angle, rotation: _rotation, baseY: baseY);
            if (!point.isVisible) continue;
            final zigzag = math.sin(i * 0.9) * width * 0.16;
            visible.add(_ProjectedNode(
              node: _nodes[i],
              point: point,
              centerX: width / 2 + zigzag,
            ));
          }

          final decorPieces = <_ProjectedDecor>[];
          for (final d in _decorScatter.forRange(start * _anglePerLevel, end * _anglePerLevel)) {
            final point =
                _projection.project(angle: d.angle, rotation: _rotation, baseY: baseY);
            if (!point.isVisible) continue;
            decorPieces.add(_ProjectedDecor(
              decor: d,
              point: point,
              centerX: width / 2 + d.side * width * 0.45 * point.scale,
            ));
          }

          // Nearer (bigger) items -- nodes and decor alike -- must overlap
          // farther ones, so both are depth-sorted together rather than
          // decor simply sitting behind every level button.
          //
          // Each item also gets a contact shadow: a soft ellipse at its
          // foot, shrinking/fading with the exact same `point` the item
          // itself uses, so it tracks the curve instead of just floating
          // underneath. Its sort key is nudged a hair below the item's own
          // scale so it always lands immediately behind its owner --
          // `List.sort` isn't guaranteed stable, so equal keys could
          // otherwise land in either order.
          final sceneItems = <_SceneItem>[
            for (final v in visible) ...[
              _SceneItem(
                scale: v.point.scale - _shadowSortEpsilon,
                widget: _contactShadow(
                  point: v.point,
                  centerX: v.centerX,
                  footY: v.point.dy + 34 * v.point.scale,
                  baseWidth: 54,
                ),
              ),
              _SceneItem(
                scale: v.point.scale,
                widget: Positioned(
                  top: v.point.dy - 34 * v.point.scale,
                  left: v.centerX - 34 * v.point.scale,
                  child: Opacity(
                    opacity: v.point.opacity,
                    child: Transform.scale(
                      scale: v.point.scale,
                      child: _LevelNode(
                        node: v.node,
                        onTap: () => _openLevel(v.node),
                        period: _period,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            for (final d in decorPieces) ...[
              _SceneItem(
                scale: d.point.scale - _shadowSortEpsilon,
                widget: _contactShadow(
                  point: d.point,
                  centerX: d.centerX,
                  footY: d.point.dy + 60 * d.point.scale,
                  baseWidth: 70,
                ),
              ),
              _SceneItem(
                scale: d.point.scale,
                widget: Positioned(
                  top: d.point.dy - 60 * d.point.scale,
                  left: d.centerX - 40 * d.point.scale,
                  child: Opacity(
                    opacity: d.point.opacity,
                    child: Transform.scale(
                      scale: d.point.scale,
                      child: _DecorPiece(decor: d.decor.variant, flipped: d.decor.flipped),
                    ),
                  ),
                ),
              ),
            ],
          ]..sort((a, b) => a.scale.compareTo(b.scale));

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Sky: fixed, never affected by the scroll -- per the spec,
                // "jamais affecté par le mouvement."
                Image.asset(_skyAsset, fit: BoxFit.cover),
                if (_period == DayNightPeriod.night)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: height * 0.35,
                    child: const TwinkleField(assets: _twinkleAssets),
                  ),
                for (var i = 0; i < _cloudCount; i++)
                  Positioned(
                    left: _cloudSlots[i].left * width,
                    top: _cloudSlots[i].top * height,
                    width: _cloudSlots[i].width * width,
                    child: Image.asset(_cloudAssets[i % _cloudAssets.length]),
                  ),
                // Ground: no horizon/hill art yet, so this is a plain
                // horizontal cutoff rather than a shaped hillside -- a
                // reasonable placeholder split, not a measured one.
                Positioned(
                  left: 0,
                  right: 0,
                  top: height * 0.35,
                  bottom: 0,
                  child: CustomPaint(
                    painter: _GrassPainter(_grassPlain, _grassTuft),
                  ),
                ),
                CustomPaint(
                  size: Size(width, height),
                  painter: _PathPainter(visible, _pathTexture),
                ),
                for (final item in sceneItems) item.widget,
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _Hud(
                    lives: _progress?.lives,
                    coins: _progress?.coins,
                    onLives: () => _openStub('Les vies -- déjà géré par 04-systemes-progression-et-xp.md, pas encore affiché ici.'),
                    onCoins: () => _openStub('La monnaie -- pas encore d\'écran dédié.'),
                    onMap: () {}, // already here
                    onRewards: () => _openStub("L'écran de récompenses n'est pas encore spécifié."),
                    onShop: () => _openStub("14-boutique.md n'est pas encore construit."),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A fixed cloud position, as a fraction of the sky area -- see
/// `_cloudSlots`.
class _CloudSlot {
  const _CloudSlot({required this.left, required this.top, required this.width});

  final double left;
  final double top;
  final double width;
}

class _ProjectedNode {
  const _ProjectedNode({
    required this.node,
    required this.point,
    required this.centerX,
  });

  final LevelMapNode node;
  final CylinderPoint point;
  final double centerX;
}

class _ProjectedDecor {
  const _ProjectedDecor({
    required this.decor,
    required this.point,
    required this.centerX,
  });

  final ScatteredDecor decor;
  final CylinderPoint point;
  final double centerX;
}

/// A node or decor piece already positioned, paired with its scale so the
/// two kinds can be depth-sorted together (see `sceneItems` in `build`).
class _SceneItem {
  const _SceneItem({required this.scale, required this.widget});

  final double scale;
  final Widget widget;
}

/// A stroked line through the visible nodes' centers, painted with the
/// real sand texture once it's loaded (flat tan color as a fallback while
/// it isn't). The path itself is still a stand-in for real sand-path art
/// (with a sculpted edge, footprints, etc.) -- this just stops the
/// interior from being a flat color.
class _PathPainter extends CustomPainter {
  _PathPainter(this.nodes, this.texture);

  final List<_ProjectedNode> nodes;
  final ui.Image? texture;

  /// Shrinks the (1024px) source texture so it repeats roughly every
  /// ~185 logical px along the path instead of one giant blotch per
  /// screen, reasoned against the path's own ~48px stroke width -- not
  /// verified on a device (this environment can't run Flutter), so the
  /// exact tiling frequency may need a pass once someone can see it.
  static const double _textureScale = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;
    final sorted = [...nodes]..sort((a, b) => a.point.dy.compareTo(b.point.dy));
    final path = Path()..moveTo(sorted.first.centerX, sorted.first.point.dy);
    for (final n in sorted.skip(1)) {
      path.lineTo(n.centerX, n.point.dy);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final tex = texture;
    if (tex != null) {
      // TileMode.mirror rather than .repeated: mirroring always matches
      // pixel-for-pixel at each tile edge, so the texture repeats with no
      // visible seam even though the source photo isn't seamless.
      paint.shader = ImageShader(
        tex,
        TileMode.mirror,
        TileMode.mirror,
        (Matrix4.identity()..scale(_textureScale)).storage,
      );
    } else {
      paint.color = const Color(0xFFD8B888).withOpacity(0.65);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => true;
}

/// The ground: a seamlessly-tiled plain-green base (`plain`, via the same
/// mirrored `ImageShader` trick as the path) with `tuft` stamped sparsely
/// on top at scattered, jittered positions -- "des fois tu mets l'image
/// vert, des fois tu mets l'image vert avec la touffe d'herbe." `tuft`'s
/// own edges are pre-feathered to transparent (see mobile/README.md), so
/// each stamp blends into the base without a visible square border.
class _GrassPainter extends CustomPainter {
  _GrassPainter(this.plain, this.tuft);

  final ui.Image? plain;
  final ui.Image? tuft;

  static const double _baseScale = 0.55;
  static const double _cellSize = 130;
  static const double _tuftChance = 0.4;

  @override
  void paint(Canvas canvas, Size size) {
    final base = plain;
    if (base == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF6FBF4A));
    } else {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ImageShader(
            base,
            TileMode.mirror,
            TileMode.mirror,
            (Matrix4.identity()..scale(_baseScale)).storage,
          ),
      );
    }

    final tuftImage = tuft;
    if (tuftImage == null) return;
    final cols = (size.width / _cellSize).ceil();
    final rows = (size.height / _cellSize).ceil();
    final srcRect = Rect.fromLTWH(
      0,
      0,
      tuftImage.width.toDouble(),
      tuftImage.height.toDouble(),
    );
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        // Seeded per cell (not per frame) so the layout is stable across
        // rebuilds instead of re-rolling every scroll tick.
        final rng = math.Random(row * 92821 + col * 68917);
        if (rng.nextDouble() > _tuftChance) continue;
        final cx = (col + 0.5) * _cellSize + (rng.nextDouble() - 0.5) * _cellSize * 0.5;
        final cy = (row + 0.5) * _cellSize + (rng.nextDouble() - 0.5) * _cellSize * 0.5;
        final scale = 0.6 + rng.nextDouble() * 0.5;
        final tileSize = _cellSize * scale;

        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate((rng.nextDouble() - 0.5) * 0.35);
        canvas.drawImageRect(
          tuftImage,
          srcRect,
          Rect.fromCenter(center: Offset.zero, width: tileSize, height: tileSize),
          Paint()..filterQuality = FilterQuality.medium,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GrassPainter oldDelegate) =>
      plain != oldDelegate.plain || tuft != oldDelegate.tuft;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.node, required this.onTap, required this.period});

  final LevelMapNode node;
  final VoidCallback onTap;
  final DayNightPeriod period;

  static const double _diameter = 68;

  // The real art's metal bezel extends past the plain circle the
  // placeholder used, so it's displayed wider than `_diameter` -- both
  // the unlit and lit variants share this width so nodes stay evenly
  // spaced regardless of validated state.
  static const double _artWidth = _diameter * 1.55;

  // Real art only for day/golden hour so far (the creator: "jour et
  // golden hour c'est les meme"). Night is still the placeholder circle
  // below -- the creator's explicit ask is that night's validated glow
  // read as noticeably brighter than day's, so reusing this day art for
  // night (like the other decor layers do while waiting on their own
  // night set) would misrepresent that once the night art actually
  // arrives.
  static const Map<LevelButtonColor, String> _unlitAsset = {
    LevelButtonColor.blue: 'assets/progression_map/button_blue_day.png',
    LevelButtonColor.purple: 'assets/progression_map/button_purple_day.png',
    LevelButtonColor.pink: 'assets/progression_map/button_pink_day.png',
    LevelButtonColor.lightBlue: 'assets/progression_map/button_lightblue_day.png',
  };
  static const Map<LevelButtonColor, String> _litAsset = {
    LevelButtonColor.blue: 'assets/progression_map/button_blue_day_lit.png',
    LevelButtonColor.purple: 'assets/progression_map/button_purple_day_lit.png',
    LevelButtonColor.pink: 'assets/progression_map/button_pink_day_lit.png',
    LevelButtonColor.lightBlue: 'assets/progression_map/button_lightblue_day_lit.png',
  };

  Color get _baseColor {
    switch (node.color) {
      case LevelButtonColor.purple:
        return const Color(0xFF9B7EDE);
      case LevelButtonColor.blue:
        return const Color(0xFF6FA8E0);
      case LevelButtonColor.pink:
        return const Color(0xFFE887B0);
      case LevelButtonColor.lightBlue:
        return const Color(0xFF7FD4E8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useRealArt = period != DayNightPeriod.night;
    const numberStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
    );
    return SpringButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _StarsRow._rowHeight,
            child: node.validated && node.stars > 0
                ? _StarsRow(count: node.stars)
                : null,
          ),
          if (useRealArt)
            SizedBox(
              width: _artWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    node.validated ? _litAsset[node.color]! : _unlitAsset[node.color]!,
                    width: _artWidth,
                  ),
                  Text('${node.number}', style: numberStyle),
                ],
              ),
            )
          else
            Container(
              width: _diameter,
              height: _diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [_baseColor.withOpacity(0.95), _baseColor],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.85), width: 3),
                boxShadow: node.validated
                    ? [BoxShadow(color: _baseColor.withOpacity(0.85), blurRadius: 18, spreadRadius: 4)]
                    : const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Text('${node.number}', style: numberStyle),
            ),
        ],
      ),
    );
  }
}

/// The 1-3 star rating above a validated level node. One real star
/// asset (`assets/progression_map/star.png`), reused at different sizes
/// rather than 3 separate cutouts -- the source render was the same
/// star at 3 scales anyway. Per the creator ("la place s'adapte en
/// fonction du nombre gagne"), the layout itself changes with the
/// count rather than just hiding unearned slots: 1 is a single
/// centered star, 2 are two even stars side by side, and 3 uses the
/// classic bigger-and-raised center star (matching the reference image
/// the creator sent) rather than 3 even stars in a row.
class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.count});

  final int count;

  static const String _asset = 'assets/progression_map/star.png';
  static const double _small = 16;
  static const double _big = 24;
  static const double _centerRaise = 6;
  static const double _rowHeight = _big + _centerRaise;

  @override
  Widget build(BuildContext context) {
    switch (count) {
      case 1:
        return const Center(child: Image.asset(_asset, width: _small + 4, height: _small + 4));
      case 2:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Image.asset(_asset, width: _small, height: _small),
            SizedBox(width: 6),
            Image.asset(_asset, width: _small, height: _small),
          ],
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Image.asset(_asset, width: _small, height: _small),
            SizedBox(width: 4),
            Padding(
              padding: EdgeInsets.only(bottom: _centerRaise),
              child: Image.asset(_asset, width: _big, height: _big),
            ),
            SizedBox(width: 4),
            Image.asset(_asset, width: _small, height: _small),
          ],
        );
    }
  }
}

/// Renders one scattered decor piece. Since `DecorScatter`'s pools are
/// empty until real art exists, this only ever runs once variants are
/// registered -- nothing to see yet, but ready.
class _DecorPiece extends StatelessWidget {
  const _DecorPiece({required this.decor, required this.flipped});

  final DecorVariant decor;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(decor.assetName, width: 96 * decor.baseScale);
    if (!flipped) return image;
    return Transform.flip(flipX: true, child: image);
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.lives,
    required this.coins,
    required this.onLives,
    required this.onCoins,
    required this.onMap,
    required this.onRewards,
    required this.onShop,
  });

  final int? lives;
  final int? coins;
  final VoidCallback onLives;
  final VoidCallback onCoins;
  final VoidCallback onMap;
  final VoidCallback onRewards;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HudPill(children: [
            _HudButton(
              imageAsset: 'assets/hud/hud_heart.png',
              color: Colors.pinkAccent,
              label: lives?.toString(),
              onTap: onLives,
            ),
            // Same coin as 03-assets-de-jeu.md's currency -- already exists.
            _HudButton(
              imageAsset: Currency.coinCafe.assetName,
              color: const Color(0xFFE7B93B),
              label: coins?.toString(),
              onTap: onCoins,
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HudPill(children: [
            _HudButton(
              imageAsset: 'assets/hud/hud_compass.png',
              color: const Color(0xFFC9A15A),
              onTap: onMap,
            ),
            // Same café-latte cup as the "café latte" boost -- the
            // creator confirmed it's the rewards icon too, no new asset.
            _HudButton(
              imageAsset: 'assets/boosts/boost-cafe-latte.png',
              color: const Color(0xFF8A5A3B),
              onTap: onRewards,
            ),
            _HudButton(
              imageAsset: 'assets/hud/hud_shop.png',
              color: const Color(0xFF3FA796),
              onTap: onShop,
            ),
          ]),
        ),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    this.icon,
    this.imageAsset,
    required this.color,
    required this.onTap,
    this.label,
  }) : assert(icon != null || imageAsset != null, 'need an icon or an image');

  /// Placeholder for whichever HUD icons don't have real art yet.
  final IconData? icon;

  /// Real art, when it already exists (e.g. an asset shared with another
  /// screen) -- takes priority over [icon] when both are set.
  final String? imageAsset;

  final Color color;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: imageAsset != null
                ? ClipOval(
                    child: Image.asset(imageAsset!, width: 36, height: 36, fit: BoxFit.cover),
                  )
                : Icon(icon, color: Colors.white, size: 18),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(label!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}
