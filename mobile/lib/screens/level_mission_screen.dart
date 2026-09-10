import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/boost.dart';
import '../models/boost_inventory.dart';
import '../models/boost_power.dart';
import '../models/level_map_node.dart';
import '../models/level_mission.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/spring_button.dart';

/// 10-fiche-mission-niveau.md: the mission sheet shown when a level node
/// on the progression map is tapped. Per the spec it's an overlay *in
/// front of* the map rather than a screen that replaces it ("carte
/// visible en arrière-plan") -- pushed via a non-opaque route
/// (see `_openLevel` in progression_map_screen.dart) so the map stays
/// mounted and visible, blurred and dimmed, behind this.
class LevelMissionScreen extends StatefulWidget {
  const LevelMissionScreen({super.key, required this.node});

  final LevelMapNode node;

  @override
  State<LevelMissionScreen> createState() => _LevelMissionScreenState();
}

class _LevelMissionScreenState extends State<LevelMissionScreen> {
  late final LevelMission _mission = LevelMissionGenerator.forLevel(widget.node.number);
  final Set<Boost> _selected = {};

  void _toggleBoost(Boost boost) {
    final owned = BoostInventory.placeholder[boost] ?? 0;
    if (owned <= 0) return;
    setState(() {
      if (!_selected.remove(boost) && _selected.length < maxEquippedBoosts) {
        _selected.add(boost);
      }
    });
  }

  void _play() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComingSoonScreen(
        message: 'Le niveau ${widget.node.number} arrive avec 11-ecran-de-jeu.md.',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            alignment: Alignment.center,
            child: GestureDetector(
              // Swallows taps landing on the card so they don't fall
              // through to the scrim's dismiss handler above.
              onTap: () {},
              child: _MissionCard(
                node: widget.node,
                mission: _mission,
                selected: _selected,
                onToggleBoost: _toggleBoost,
                onPlay: _play,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.node,
    required this.mission,
    required this.selected,
    required this.onToggleBoost,
    required this.onPlay,
  });

  final LevelMapNode node;
  final LevelMission mission;
  final Set<Boost> selected;
  final ValueChanged<Boost> onToggleBoost;
  final VoidCallback onPlay;

  static const _brown = Color(0xFF6B4226);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      // "Verre dépoli mat façon velours, blanchâtre et légèrement
      // transparent" -- a matte, semi-opaque white card. It has no blur
      // filter of its own: the screen-wide BackdropFilter behind it
      // already blurs the map, so the card's own translucency is what
      // lets a soft hint of that blurred map show through.
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OutlinedTitle('Niveau ${node.number}'),
          const SizedBox(height: 20),
          _MissionRow(mission: mission),
          const SizedBox(height: 20),
          CustomPaint(painter: _DashedLinePainter(), size: const Size(double.infinity, 1.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final boost in Boost.values)
                _BoostSlot(
                  boost: boost,
                  owned: BoostInventory.placeholder[boost] ?? 0,
                  selected: selected.contains(boost),
                  onTap: () => onToggleBoost(boost),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: SpringButton(
              onPressed: onPlay,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _brown,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3))],
                ),
                child: const Text(
                  'JOUER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brown fill text with a white outline, mimicking the mockup's
/// sticker-style title -- stacks 4 offset white copies behind the real
/// text rather than relying on a stroke-only Paint (which Flutter doesn't
/// blend cleanly with a separate fill pass at small sizes).
class _OutlinedTitle extends StatelessWidget {
  const _OutlinedTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1);
    const offsets = [
      Offset(-1.5, -1.5), Offset(1.5, -1.5), Offset(-1.5, 1.5), Offset(1.5, 1.5),
      Offset(-1.5, 0), Offset(1.5, 0), Offset(0, -1.5), Offset(0, 1.5),
    ];
    return Stack(
      children: [
        for (final o in offsets)
          Transform.translate(
            offset: o,
            child: Text(text, style: style.copyWith(color: Colors.white)),
          ),
        Text(text, style: style.copyWith(color: _MissionCard._brown)),
      ],
    );
  }
}

/// The target element(s) plus the mission's headline text. 1 target gets
/// one large icon (matching the reference mockup); 2 targets share the
/// same slot as a smaller pair, per the spec's "peut porter sur plusieurs
/// éléments à la fois" -- kept to 2 so it still fits the card's fixed
/// width cleanly ("bien s'adapter visuellement à la fiche").
class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission});

  final LevelMission mission;

  @override
  Widget build(BuildContext context) {
    final iconSize = mission.targets.length == 1 ? 96.0 : 64.0;
    return Row(
      children: [
        if (mission.targets.length == 1)
          Image.asset(mission.targets.single.element.assetName, width: iconSize, height: iconSize)
        else
          SizedBox(
            width: iconSize + 20,
            height: iconSize,
            child: Stack(
              children: [
                for (var i = 0; i < mission.targets.length; i++)
                  Positioned(
                    left: i * 20,
                    top: i * 16,
                    child: Image.asset(
                      mission.targets[i].element.assetName,
                      width: iconSize,
                      height: iconSize,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            mission.type.title,
            style: const TextStyle(
              color: _MissionCard._brown,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9AD8F)
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One boost icon + its owned-quantity pill. Tapping toggles it in/out of
/// this level's loadout with a press-in look (per the spec: "une
/// animation d'enfoncement indique lequel est sélectionné") layered on
/// top of `SpringButton`'s game-wide tap bounce -- the pill itself
/// animates to a flatter, lighter "pushed in" state while selected,
/// rather than the transient per-tap spring alone carrying that meaning.
class _BoostSlot extends StatelessWidget {
  const _BoostSlot({
    required this.boost,
    required this.owned,
    required this.selected,
    required this.onTap,
  });

  final Boost boost;
  final int owned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = owned > 0;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(boost.assetName, width: 42, height: 42),
          const SizedBox(height: 6),
          SpringButton(
            onPressed: enabled ? () => onTap() : () {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFDCC7A8) : const Color(0xFF6B4226),
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? const []
                    : const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
              ),
              child: Text(
                '$owned',
                style: TextStyle(
                  color: selected ? const Color(0xFF6B4226) : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
