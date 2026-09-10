import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/boost.dart';
import '../models/day_night_period.dart';
import '../models/game_board.dart';
import '../models/game_element.dart';
import '../models/level_map_node.dart';
import '../models/level_mission.dart';

/// 11-ecran-de-jeu.md: the match-3 board itself. This is the "cœur"
/// pass only -- see mobile/README.md for the full list of what's
/// deliberately deferred (special pieces, obstacles, delivery objectives,
/// boost activation, the hint glow, the shuffle animation, and the real
/// win/lose animations, all stood in here with something honest and
/// simple instead).
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.node,
    required this.mission,
    required this.selectedBoosts,
    this.livesRemaining,
  });

  final LevelMapNode node;
  final LevelMission mission;
  final Set<Boost> selectedBoosts;
  final int? livesRemaining;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // The spec's own 7x7 reference board. "La difficulté augmente sur les
  // niveaux suivants" is stated but never quantified (board size curve,
  // move budget curve, etc.) -- no per-level scaling exists yet, every
  // level plays the same reference board until real balancing data does.
  static const int _boardSize = 7;

  // The spec's own worked example: "les chiffres visibles sur cet exemple
  // sont les valeurs réelles d'un niveau facile" -- 25 moves is the one
  // real anchor given, reused for every level for the same reason as the
  // board size above.
  static const int _startingMoves = 25;

  // "Poussière d'étoiles... le gain est proportionnel à la difficulté du
  // niveau" is the only rule given for star-dust, with no formula or
  // thresholds -- these are reasoned placeholders (1 star-dust per
  // cleared piece, a flat per-leftover-move bonus at victory, and
  // thresholds anchored to the mission's own size) until real balancing
  // data exists, not measured values.
  static const int _starDustPerRemainingMove = 3;

  late final GameBoard _board = GameBoard(rows: _boardSize, cols: _boardSize);
  late final Map<GameElement, int> _missionRemaining = {
    for (final t in widget.mission.targets) t.element: t.count,
  };
  late final DayNightPeriod _period = DayNightSchedule.current();
  late final int _starTarget1 = math.max(1, _missionTotal);
  late final int _starTarget2 = (_starTarget1 * 1.5).round();
  late final int _starTarget3 = _starTarget1 * 2;

  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(() => setState(() {}));

  int _movesLeft = _startingMoves;
  int _starDust = 0;
  BoardPoint? _selected;
  BoardPoint? _bounceA;
  BoardPoint? _bounceB;
  bool _resolved = false;

  int get _missionTotal => widget.mission.targets.fold(0, (a, t) => a + t.count);
  bool get _missionComplete => _missionRemaining.values.every((v) => v <= 0);

  int get _starsEarned {
    if (_starDust >= _starTarget3) return 3;
    if (_starDust >= _starTarget2) return 2;
    if (_starDust >= _starTarget1) return 1;
    return 0;
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onCellTap(BoardPoint p) {
    if (_resolved) return;
    final current = _selected;
    if (current == null) {
      setState(() => _selected = p);
      return;
    }
    if (current == p) {
      setState(() => _selected = null);
      return;
    }
    if (current.isAdjacentTo(p)) {
      setState(() => _selected = null);
      _attemptSwap(current, p);
    } else {
      setState(() => _selected = p);
    }
  }

  void _onSwipe(BoardPoint start, Offset delta) {
    if (_resolved) return;
    // Whichever axis moved further decides the swap direction; a drag
    // that barely moved isn't treated as an attempt at all.
    const threshold = 12.0;
    if (delta.dx.abs() < threshold && delta.dy.abs() < threshold) return;
    BoardPoint target;
    if (delta.dx.abs() > delta.dy.abs()) {
      target = BoardPoint(start.x + (delta.dx > 0 ? 1 : -1), start.y);
    } else {
      target = BoardPoint(start.x, start.y + (delta.dy > 0 ? 1 : -1));
    }
    if (target.x < 0 || target.x >= _boardSize || target.y < 0 || target.y >= _boardSize) return;
    setState(() => _selected = null);
    _attemptSwap(start, target);
  }

  void _attemptSwap(BoardPoint a, BoardPoint b) {
    final valid = _board.trySwap(a, b);
    if (!valid) {
      setState(() {
        _bounceA = a;
        _bounceB = b;
      });
      _bounceController.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _bounceA = null;
          _bounceB = null;
        });
      });
      return;
    }

    final result = _board.resolveCascade();
    for (final entry in result.clearedByElement.entries) {
      final remaining = _missionRemaining[entry.key];
      if (remaining != null) {
        _missionRemaining[entry.key] = math.max(0, remaining - entry.value);
      }
    }
    setState(() {
      _movesLeft = math.max(0, _movesLeft - 1);
      _starDust += result.totalCleared;
    });
    _checkEndOfLevel();
  }

  void _checkEndOfLevel() {
    if (_resolved) return;
    if (_missionComplete) {
      _resolved = true;
      // "Victoire avec mouvements restants: une étoile filante par
      // mouvement restant... rejoint la barre des étoiles." The real
      // per-move shooting-star animation isn't built (see README); the
      // star-dust value it would have contributed is still counted.
      setState(() => _starDust += _movesLeft * _starDustPerRemainingMove);
      _finishLevel(won: true);
    } else if (_movesLeft <= 0) {
      _resolved = true;
      _finishLevel(won: false);
    } else if (!_board.hasAnyValidMove()) {
      setState(() => _board.shuffleUntilPlayable());
    }
  }

  void _finishLevel({required bool won}) {
    // 11-ecran-de-jeu.md is explicit that the real win/lose animations
    // (star + score reveal, the lost-level animation) aren't built yet --
    // see also 12-popups-fin-de-niveau.md. This dialog is an honest,
    // unanimated stand-in that still reports the real result.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(won ? 'Niveau ${widget.node.number} réussi !' : 'Niveau ${widget.node.number} raté'),
        content: Text(won
            ? '$_starsEarned étoile(s) -- $_starDust poussière d\'étoile au total. '
                'L\'animation de victoire (étoiles + score) n\'est pas encore '
                'construite -- voir 12-popups-fin-de-niveau.md.'
            : 'Plus de mouvements disponibles. L\'animation de défaite '
                'n\'est pas encore construite -- voir 12-popups-fin-de-niveau.md.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // game -> mission sheet
              Navigator.of(context).pop(); // mission sheet -> map
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static const Map<DayNightPeriod, String> _backgroundByPeriod = {
    // No dedicated "table de jeu" background exists yet -- reusing the
    // home screen's real (day/golden/night) background rather than
    // inventing a new photo.
    DayNightPeriod.day: 'assets/home/home_background_day.jpg',
    DayNightPeriod.goldenHour: 'assets/home/home_background_golden.jpg',
    DayNightPeriod.night: 'assets/home/home_background_night.jpg',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_backgroundByPeriod[_period]!, fit: BoxFit.cover),
          SafeArea(
            child: Column(
              children: [
                _TopHud(
                  movesLeft: _movesLeft,
                  lives: widget.livesRemaining,
                  starDust: _starDust,
                  starTargets: (_starTarget1, _starTarget2, _starTarget3),
                  mission: widget.mission,
                  missionRemaining: _missionRemaining,
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _BoardPanel(
                          board: _board,
                          boardSize: _boardSize,
                          selected: _selected,
                          bounceA: _bounceA,
                          bounceB: _bounceB,
                          bounceT: _bounceController.value,
                          onTap: _onCellTap,
                          onSwipe: _onSwipe,
                        ),
                      ),
                    ),
                  ),
                ),
                _BottomHud(selectedBoosts: widget.selectedBoosts),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardPanel extends StatelessWidget {
  const _BoardPanel({
    required this.board,
    required this.boardSize,
    required this.selected,
    required this.bounceA,
    required this.bounceB,
    required this.bounceT,
    required this.onTap,
    required this.onSwipe,
  });

  final GameBoard board;
  final int boardSize;
  final BoardPoint? selected;
  final BoardPoint? bounceA;
  final BoardPoint? bounceB;
  final double bounceT;
  final ValueChanged<BoardPoint> onTap;

  /// Called once per drag gesture with the starting cell and the total
  /// (accumulated, not velocity) offset dragged.
  final void Function(BoardPoint start, Offset delta) onSwipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      // A hand-rolled grid (Column of Rows), not GridView -- GridView's
      // own Scrollable still competes for drag gestures in the gesture
      // arena even with NeverScrollableScrollPhysics (it disables
      // scrolling, not arena participation), which would fight each
      // cell's own pan handling below, especially for vertical swipes.
      // Nothing here needs to scroll or lazily build anyway at a fixed
      // 7x7-ish size.
      child: Column(
        children: [
          for (var y = 0; y < boardSize; y++)
            Expanded(
              child: Row(
                children: [
                  for (var x = 0; x < boardSize; x++)
                    Expanded(child: _cell(BoardPoint(x, y))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(BoardPoint p) {
    // "Punch" scale for the two cells mid-bounce -- a squash-in,
    // spring-out read as the "effet de rebond" the spec asks for on a
    // rejected swap, without modeling the two cells actually sliding
    // toward each other and back.
    final isBouncing = p == bounceA || p == bounceB;
    final punch = isBouncing ? 1 - math.sin(bounceT * math.pi) * 0.18 : 1.0;
    var dragDelta = Offset.zero;
    return GestureDetector(
      onTap: () => onTap(p),
      onPanStart: (_) => dragDelta = Offset.zero,
      onPanUpdate: (details) => dragDelta += details.delta,
      onPanEnd: (_) => onSwipe(p, dragDelta),
      child: Transform.scale(
        scale: punch,
        child: _BoardCell(element: board.elementAt(p), selected: p == selected),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({required this.element, required this.selected});

  final GameElement element;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withOpacity(0.55) : Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Image.asset(element.assetName, fit: BoxFit.contain),
    );
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.movesLeft,
    required this.lives,
    required this.starDust,
    required this.starTargets,
    required this.mission,
    required this.missionRemaining,
  });

  final int movesLeft;
  final int? lives;
  final int starDust;
  final (int, int, int) starTargets;
  final LevelMission mission;
  final Map<GameElement, int> missionRemaining;

  static const _pink = Color(0xFFEF7E93);
  static const _pinkText = Color(0xFFC85068);

  @override
  Widget build(BuildContext context) {
    final remaining = missionRemaining.values.fold(0, (a, b) => a + b);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(28)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('$movesLeft', style: const TextStyle(color: _pinkText, fontWeight: FontWeight.w900, fontSize: 26)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StarBar(starDust: starDust, targets: starTargets),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < mission.targets.length; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                        child: Image.asset(mission.targets[i].element.assetName, width: 26, height: 26),
                      ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.white,
                      child: Text('$remaining', style: const TextStyle(color: _pinkText, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${lives ?? '?'}/10',
            style: const TextStyle(color: _pinkText, fontWeight: FontWeight.w900, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _StarBar extends StatelessWidget {
  const _StarBar({required this.starDust, required this.targets});

  final int starDust;
  final (int, int, int) targets;

  @override
  Widget build(BuildContext context) {
    final (t1, t2, t3) = targets;
    final fraction = (starDust / t3).clamp(0.0, 1.0);
    return SizedBox(
      width: double.infinity,
      height: 22,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // left:0/right:0 (not a bare Container) so the track and fill
          // bars actually span the bar's width -- an un-positioned Stack
          // child with no intrinsic width of its own collapses to zero
          // rather than filling loose constraints. Fixed height+top
          // instead of Positioned.fill, which would stretch it to the
          // whole 22px-tall Stack rather than staying a thin 4px line.
          Positioned(
            left: 0,
            right: 0,
            top: 9,
            height: 4,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 9,
            height: 4,
            child: FractionallySizedBox(
              widthFactor: fraction,
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 11),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          for (final t in [t1, t2, t3])
            Align(
              alignment: Alignment(-1 + 2 * (t / t3), 0),
              child: Opacity(
                opacity: starDust >= t ? 1 : 0.45,
                child: Image.asset('assets/progression_map/star.png', width: 18, height: 18),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomHud extends StatelessWidget {
  const _BottomHud({required this.selectedBoosts});

  final Set<Boost> selectedBoosts;

  @override
  Widget build(BuildContext context) {
    if (selectedBoosts.isEmpty) return const SizedBox(height: 12);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFEF7E93), borderRadius: BorderRadius.circular(28)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final boost in selectedBoosts)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(boost.assetName, width: 40, height: 40),
                const SizedBox(height: 4),
                // Boost activation (tapping to actually use one in-level)
                // isn't built yet -- this just displays the loadout
                // chosen on the mission sheet.
                const Text('0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }
}
