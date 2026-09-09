import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../models/currency.dart';
import '../models/decor_variant.dart';
import '../models/level_map_node.dart';
import '../networking/api_client.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/cylinder_projection.dart';
import '../widgets/decor_scatter.dart';
import '../widgets/spring_button.dart';

/// 09-carte-progression.md: the level map. Real decor art (palm trees,
/// the "Coffee Bar" building, sand path texture) isn't in yet -- this is
/// the scroll mechanism and level-node behavior on placeholder shapes, to
/// be re-skinned once those assets arrive. Deliberately deferred for this
/// pass, same as earlier files' pattern of modeling a not-yet-buildable
/// system as data/behavior first: the day/night cycle, the biome change
/// every 10 levels, and infinite level generation past the first 1000
/// preloaded (see `LevelMapGenerator`).
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

  /// Empty pools until the creator's decor art is in -- registering a
  /// variant here is the only wiring `DecorScatter` needs to start
  /// placing it (see mobile/README.md, 09-carte-progression.md section).
  static const DecorScatter _decorScatter = DecorScatter(
    fillerPool: [],
    landmarkPool: [],
    anglePerLevel: _anglePerLevel,
  );

  late final AnimationController _flingController;
  double _rotation = 0;
  List<LevelMapNode> _nodes =
      LevelMapGenerator.generatePreloaded(unlockedLevel: 0);
  ProgressDTO? _progress;

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
    _flingController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _rotation = _clampRotation(_flingController.value);
        });
      });
    _loadProgress();
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

  @override
  void dispose() {
    _flingController.dispose();
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
          final sceneItems = <_SceneItem>[
            for (final v in visible)
              _SceneItem(
                scale: v.point.scale,
                widget: Positioned(
                  top: v.point.dy - 34 * v.point.scale,
                  left: v.centerX - 34 * v.point.scale,
                  child: Opacity(
                    opacity: v.point.opacity,
                    child: Transform.scale(
                      scale: v.point.scale,
                      child: _LevelNode(node: v.node, onTap: () => _openLevel(v.node)),
                    ),
                  ),
                ),
              ),
            for (final d in decorPieces)
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
          ]..sort((a, b) => a.scale.compareTo(b.scale));

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Sky: fixed, never affected by the scroll -- placeholder
                // gradient until the real sky art is in.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6EC6E8), Color(0xFFA8DFF0)],
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size(width, height),
                  painter: _PathPainter(visible),
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

/// Placeholder for the sand path texture: a stroked line through the
/// visible nodes' centers, so the zigzag/curve is visible before the real
/// art exists.
class _PathPainter extends CustomPainter {
  _PathPainter(this.nodes);

  final List<_ProjectedNode> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;
    final sorted = [...nodes]..sort((a, b) => a.point.dy.compareTo(b.point.dy));
    final path = Path()..moveTo(sorted.first.centerX, sorted.first.point.dy);
    for (final n in sorted.skip(1)) {
      path.lineTo(n.centerX, n.point.dy);
    }
    final paint = Paint()
      ..color = const Color(0xFFD8B888).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => true;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.node, required this.onTap});

  final LevelMapNode node;
  final VoidCallback onTap;

  static const double _diameter = 68;

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
    return SpringButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 20,
            child: node.validated && node.stars > 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      node.stars,
                      (_) => const Icon(Icons.star,
                          color: Color(0xFFFFD34D), size: 18),
                    ),
                  )
                : null,
          ),
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
            child: Text(
              '${node.number}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
            _HudButton(icon: Icons.favorite, color: Colors.pinkAccent, label: lives?.toString(), onTap: onLives),
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
            _HudButton(icon: Icons.explore, color: const Color(0xFFC9A15A), onTap: onMap),
            // Same café-latte cup as the "café latte" boost -- the
            // creator confirmed it's the rewards icon too, no new asset.
            _HudButton(
              imageAsset: 'assets/boosts/boost-cafe-latte.png',
              color: const Color(0xFF8A5A3B),
              onTap: onRewards,
            ),
            _HudButton(icon: Icons.storefront, color: const Color(0xFF3FA796), onTap: onShop),
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
