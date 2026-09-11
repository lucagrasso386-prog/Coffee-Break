import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/boost.dart';
import '../models/level_map_node.dart';
import '../models/level_mission.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/loading_transition_overlay.dart';
import '../widgets/spring_button.dart';
import '../widgets/sticker_text.dart';
import 'game_screen.dart';
import 'progression_map_screen.dart';
import 'shop_screen.dart';

/// 12-popups-fin-de-niveau.md: the two end-of-level popups (lost/won),
/// pushed from `GameScreen._finishLevel`. Same "verre dépoli mat façon
/// velours" card style as the mission sheet (`level_mission_screen.dart`)
/// -- reusing `StickerText` for the titles and the same
/// blur-scrim-over-whatever's-behind overlay pattern.

const _brown = Color(0xFF6B4226);
const _coral = Color(0xFFE8836B);

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
      ],
    );

/// Wraps [card] in the shared blur+scrim backdrop, plus an optional
/// full-screen [background] layer between the scrim and the card (the
/// victory popup's fireworks). [card] is centered as a whole -- when it
/// needs to carry its own corner badge (the lost popup's "X"), that
/// badge has to be part of [card] itself (see `_withCloseButton` below),
/// not positioned by this scaffold: a `Positioned` here would be placed
/// relative to the full-screen backdrop, not the card, since the
/// backdrop -- not the card -- is what actually sizes this outer Stack.
class _PopupScaffold extends StatelessWidget {
  const _PopupScaffold({required this.card, this.background});

  final Widget card;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withOpacity(0.45),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (background != null) Positioned.fill(child: IgnorePointer(child: background!)),
              card,
            ],
          ),
        ),
      ),
    );
  }
}

/// Attaches the lost popup's bottom-left "X" dismiss badge to [card],
/// overlapping its corner (per the reference mockup) -- a Stack sized by
/// [card] itself (the only non-`Positioned` child), so the badge anchors
/// to the card's own bounds regardless of where the whole thing ends up
/// centered on screen.
Widget _withCloseButton({required Widget card, required VoidCallback onDismiss}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      card,
      Positioned(
        left: 4,
        bottom: -4,
        child: SpringButton(
          onPressed: onDismiss,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _brown,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: const Text('X', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    ],
  );
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SpringButton(
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _brown,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3))],
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Both popups leave the mission-sheet/game-screen stack behind entirely
/// rather than popping through it -- `pushAndRemoveUntil` with a
/// `LoadingTransitionOverlay` wrapping the destination, matching the
/// spec's own "animation de chargement" language for every one of these
/// transitions (X, Rejouer, Continuer all name it).
void _goTo(BuildContext context, WidgetBuilder destination) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => LoadingTransitionOverlay(future: Future<void>.value(), builder: destination),
    ),
    (route) => false,
  );
}

class LevelLostPopup extends StatelessWidget {
  const LevelLostPopup({
    super.key,
    required this.node,
    required this.mission,
    required this.selectedBoosts,
    required this.livesRemaining,
  });

  final LevelMapNode node;
  final LevelMission mission;
  final Set<Boost> selectedBoosts;
  final int? livesRemaining;

  void _replay(BuildContext context) {
    // "Si plus aucune vie -> le bouton redirige vers la première page de
    // la boutique (ne relance pas de partie)."
    if (livesRemaining != null && livesRemaining! <= 0) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen()));
      return;
    }
    _goTo(
      context,
      (_) => GameScreen(node: node, mission: mission, selectedBoosts: selectedBoosts, livesRemaining: livesRemaining),
    );
  }

  void _watchAdForMoves(BuildContext context) {
    // "+5 mouvements gratuit" needs a 30s+ video ad. No ad SDK is wired
    // into this project yet (nothing in pubspec.yaml) -- an honest stub
    // rather than a fake ad flow or a silently-broken button.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ComingSoonScreen(
        message: "La pub vidéo pour +5 mouvements n'est pas encore intégrée -- "
            'aucun SDK publicitaire dans le projet pour le moment.',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _PopupScaffold(
      card: _withCloseButton(
        onDismiss: () => _goTo(context, (_) => const ProgressionMapScreen()),
        card: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StickerText('PERDU', color: _coral, fontSize: 40),
              const SizedBox(height: 18),
              Text(
                '${livesRemaining ?? '?'}/10',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
                ),
              ),
              const SizedBox(height: 6),
              const Text("C'est pas fini !", style: TextStyle(color: _coral, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 22),
              _PillButton(label: '+5 MOUVEMENTS GRATUIT !', onPressed: () => _watchAdForMoves(context)),
              const SizedBox(height: 12),
              _PillButton(label: 'REJOUER', onPressed: () => _replay(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class LevelWonPopup extends StatelessWidget {
  const LevelWonPopup({super.key, required this.node, required this.score, required this.starsEarned});

  final LevelMapNode node;
  final int score;
  final int starsEarned;

  @override
  Widget build(BuildContext context) {
    return _PopupScaffold(
      background: const _Fireworks(),
      card: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StickerText('GAGNÉ', color: _coral, fontSize: 40),
            const SizedBox(height: 18),
            _CountingScore(score: score),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Opacity(
                      opacity: i < starsEarned ? 1 : 0.35,
                      child: Image.asset('assets/progression_map/star.png', width: 46, height: 46),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            _PillButton(label: 'CONTINUER', onPressed: () => _goTo(context, (_) => const ProgressionMapScreen())),
          ],
        ),
      ),
    );
  }
}

/// "Le score s'affiche en grandissant, avec un effet de comptage qui
/// incrémente par palier de 1 point" -- a scale-in pop plus a numeric
/// count-up. Read "incrémente par palier de 1" as *how* the count moves
/// (whole integers, not a smoothly interpolated fraction), not literally
/// one-at-a-time -- a real score can run into the hundreds of thousands
/// (the spec's own mockup shows "1,250,000"), and ticking that up one by
/// one would take minutes.
class _CountingScore extends StatefulWidget {
  const _CountingScore({required this.score});

  final int score;

  @override
  State<_CountingScore> createState() => _CountingScoreState();
}

class _CountingScoreState extends State<_CountingScore> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  late final Animation<int> _value = IntTween(begin: 0, end: widget.score).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _scale = Tween(begin: 0.6, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _format(int n) {
    final digits = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Transform.scale(
        scale: _scale.value,
        child: Text(
          _format(_value.value),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 32,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
      ),
    );
  }
}

/// Procedural firework bursts behind the victory card -- no real firework
/// art exists, and photographic firework content isn't something to
/// fabricate, so this is a generated effect instead (radiating, fading
/// lines from a handful of staggered burst points), in the same spirit
/// as this codebase's other procedural decoration (the twinkling stars on
/// the progression map's night sky, contact shadows). Not meant to read
/// as a real photo, just as motion and color behind the card.
class _Fireworks extends StatefulWidget {
  const _Fireworks();

  @override
  State<_Fireworks> createState() => _FireworksState();
}

class _Burst {
  const _Burst({required this.center, required this.color, required this.phase, required this.rayCount});
  final Offset center; // fractional (0-1) position within the available area
  final Color color;
  final double phase; // 0-1, staggers this burst's start within the shared loop
  final int rayCount;
}

class _FireworksState extends State<_Fireworks> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  late final List<_Burst> _bursts = List.generate(5, (i) {
    final rng = math.Random(i * 97 + 11);
    const colors = [Color(0xFF4F9DE0), Color(0xFFE0A63A), Color(0xFFE0596B), Color(0xFF6FB98F)];
    return _Burst(
      center: Offset(rng.nextDouble(), rng.nextDouble() * 0.7),
      color: colors[i % colors.length],
      phase: i / 5,
      rayCount: 9 + rng.nextInt(5),
    );
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No explicit CustomPaint `size` needed -- this sits inside a
    // Positioned.fill up in _PopupScaffold, which already hands it tight
    // (exact) constraints.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _FireworksPainter(bursts: _bursts, t: _controller.value)),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  const _FireworksPainter({required this.bursts, required this.t});

  final List<_Burst> bursts;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final burst in bursts) {
      final localT = (t + burst.phase) % 1.0;
      // Each burst plays over the first 40% of its own cycle, then stays
      // invisible for the rest -- staggered by `phase` so they don't all
      // fire in unison.
      if (localT > 0.4) continue;
      final phase = localT / 0.4;
      final radius = phase * size.shortestSide * 0.22;
      final alpha = (1 - phase).clamp(0.0, 1.0);
      final center = Offset(burst.center.dx * size.width, burst.center.dy * size.height);
      final linePaint = Paint()
        ..color = burst.color.withOpacity(alpha * 0.85)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final dotPaint = Paint()
        ..color = burst.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;
      for (var i = 0; i < burst.rayCount; i++) {
        final angle = (i / burst.rayCount) * 2 * math.pi;
        final dir = Offset(math.cos(angle), math.sin(angle));
        final tip = center + dir * radius;
        canvas.drawLine(center, tip, linePaint);
        canvas.drawCircle(tip, 1.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) => oldDelegate.t != t;
}
