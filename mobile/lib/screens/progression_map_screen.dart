import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../models/level_map_node.dart';
import '../networking/api_client.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/cylinder_projection.dart';
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
          // Nearer (bigger) nodes must overlap farther ones.
          final byDepth = [...visible]
            ..sort((a, b) => a.point.scale.compareTo(b.point.scale));

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
                for (final v in byDepth)
                  Positioned(
                    top: v.point.dy - 34 * v.point.scale,
                    left: v.centerX - 34 * v.point.scale,
                    child: Opacity(
                      opacity: v.point.opacity,
                      child: Transform.scale(
                        scale: v.point.scale,
                        child: _LevelNode(
                          node: v.node,
                          onTap: () => _openLevel(v.node),
                        ),
                      ),
                    ),
                  ),
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
            _HudButton(icon: Icons.monetization_on, color: const Color(0xFFE7B93B), label: coins?.toString(), onTap: onCoins),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HudPill(children: [
            _HudButton(icon: Icons.explore, color: const Color(0xFFC9A15A), onTap: onMap),
            _HudButton(icon: Icons.local_cafe, color: const Color(0xFF8A5A3B), onTap: onRewards),
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
    required this.icon,
    required this.color,
    required this.onTap,
    this.label,
  });

  final IconData icon;
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
          CircleAvatar(radius: 18, backgroundColor: color, child: Icon(icon, color: Colors.white, size: 18)),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(label!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}
