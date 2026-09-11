import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reward_tier.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/spring_button.dart';

/// 13-ecran-recompenses.md: the battle-pass-style rewards screen, reached
/// from the map's bottom HUD "café" icon. A vertical list of tiers (30 000
/// XP each), each granting the same fixed bundle (`rewardTierBundle`) on
/// its free (left) and premium/subscriber (right) side. No back button --
/// "uniquement swipe gauche/droite pour quitter" is enforced for real
/// here (`PopScope(canPop: false)` blocks the system back button/gesture;
/// only the horizontal swipe this screen wires up itself can leave).
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key, required this.xp});

  /// Current total XP, from the map's already-fetched `ProgressDTO`.
  final int xp;

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  // Tall enough for the pill cap plus the 4 reward rows at a readable
  // size -- reasoned, not measured against a real device.
  static const double _tierCardHeight = 460;
  static const String _lastSeenXpKey = 'coffeebreak.rewardsLastSeenXp';
  static const int _preloadedTierCount = 20;

  final ScrollController _scrollController = ScrollController();

  /// Claimed-reward tracking is session-only -- there's no backend
  /// endpoint to persist a claim yet (same placeholder pattern as
  /// `BoostInventory`: honest about what's real right now, not invented).
  final Set<String> _claimed = {};

  // "Sans abonnement actif" is always true right now -- no subscription
  // state exists anywhere in this app yet (14-boutique.md isn't built).
  static const bool _hasActiveSubscription = false;

  _ClaimAnimationSpec? _claimAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runCatchUp());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _tierOffset(int xp) => (xp / xpPerRewardTier) * _tierCardHeight;

  Future<void> _runCatchUp() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getInt(_lastSeenXpKey);
    if (!mounted) return;

    if (lastSeen == null) {
      // First-ever visit to this screen -- nothing to catch up on, and
      // animating in from XP 0 every time would be wrong the one time it
      // isn't a real gap.
      await prefs.setInt(_lastSeenXpKey, widget.xp);
      return;
    }

    if (lastSeen >= widget.xp) return; // nothing accrued since last visit

    // "La barre réapparaît à l'endroit où le joueur l'avait laissée,
    // avance rapidement jusqu'à sa position actuelle en ralentissant à
    // l'arrivée" -- jump straight to the old position (no animation),
    // then ease out into the new one.
    _scrollController.jumpTo(_tierOffset(lastSeen).clamp(0, _scrollController.position.maxScrollExtent));
    await _scrollController.animateTo(
      _tierOffset(widget.xp).clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
    );
    if (!mounted) return;
    await prefs.setInt(_lastSeenXpKey, widget.xp);
  }

  void _onHorizontalSwipe(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond.dx;
    if (v.abs() > 250) Navigator.of(context).pop();
  }

  void _onTapReward({required int tierIndex, required int itemIndex, required bool premium}) {
    final unlocked = widget.xp >= (tierIndex + 1) * xpPerRewardTier;
    if (!unlocked) return;

    // One claim animation at a time -- its controller/tweens are set up
    // once in `initState`, so swapping `_claimAnimation` mid-flight would
    // silently keep animating the old spec under a new id instead of
    // restarting cleanly.
    if (_claimAnimation != null) return;

    if (premium && !_hasActiveSubscription) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const ComingSoonScreen(
          message: "La page d'abonnement de la boutique (14-boutique.md) n'est pas encore construite.",
        ),
      ));
      return;
    }

    final id = '$tierIndex-$itemIndex-${premium ? 'p' : 'f'}';
    if (_claimed.contains(id)) return;

    final item = rewardTierBundle[itemIndex];
    setState(() {
      _claimAnimation = _ClaimAnimationSpec(id: id, assetName: item.assetName);
    });
  }

  void _onClaimAnimationDone(String id) {
    if (!mounted) return;
    setState(() {
      _claimed.add(id);
      _claimAnimation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF8A6A50),
        body: GestureDetector(
          onHorizontalDragEnd: _onHorizontalSwipe,
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                itemCount: _preloadedTierCount,
                itemBuilder: (context, index) => SizedBox(
                  height: _tierCardHeight,
                  child: _TierCard(
                    tierIndex: index,
                    xp: widget.xp,
                    claimed: _claimed,
                    onTapReward: _onTapReward,
                  ),
                ),
              ),
              if (_claimAnimation != null)
                _ClaimAnimationOverlay(
                  spec: _claimAnimation!,
                  onDone: () => _onClaimAnimationDone(_claimAnimation!.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tierIndex,
    required this.xp,
    required this.claimed,
    required this.onTapReward,
  });

  final int tierIndex;
  final int xp;
  final Set<String> claimed;
  final void Function({required int tierIndex, required int itemIndex, required bool premium}) onTapReward;

  @override
  Widget build(BuildContext context) {
    final unlocked = xp >= (tierIndex + 1) * xpPerRewardTier;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 12,
                height: 340,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
              ),
            ],
          ),
          // The rounded "pill cap" sits at the top of each tier's bar --
          // per the reference mockup, a fixed marker for the tier rather
          // than an in-place fill gauge (see mobile/README.md for why).
          Container(
            width: 46,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF3FB6AE),
              borderRadius: BorderRadius.circular(23),
              boxShadow: unlocked
                  ? [BoxShadow(color: const Color(0xFF3FB6AE).withOpacity(0.7), blurRadius: 18, spreadRadius: 2)]
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 70),
            child: Column(
              children: [
                for (var i = 0; i < rewardTierBundle.length; i++)
                  _RewardRow(
                    item: rewardTierBundle[i],
                    unlocked: unlocked,
                    freeClaimed: claimed.contains('$tierIndex-$i-f'),
                    premiumClaimed: claimed.contains('$tierIndex-$i-p'),
                    onTapFree: () => onTapReward(tierIndex: tierIndex, itemIndex: i, premium: false),
                    onTapPremium: () => onTapReward(tierIndex: tierIndex, itemIndex: i, premium: true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.item,
    required this.unlocked,
    required this.freeClaimed,
    required this.premiumClaimed,
    required this.onTapFree,
    required this.onTapPremium,
  });

  final RewardItem item;
  final bool unlocked;
  final bool freeClaimed;
  final bool premiumClaimed;
  final VoidCallback onTapFree;
  final VoidCallback onTapPremium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RewardIcon(
            assetName: item.assetName,
            quantity: item.freeQuantity,
            glow: unlocked,
            claimed: freeClaimed,
            onTap: onTapFree,
          ),
          _RewardIcon(
            assetName: item.assetName,
            quantity: item.premiumQuantity,
            glow: unlocked,
            claimed: premiumClaimed,
            onTap: onTapPremium,
          ),
        ],
      ),
    );
  }
}

class _RewardIcon extends StatelessWidget {
  const _RewardIcon({
    required this.assetName,
    required this.quantity,
    required this.glow,
    required this.claimed,
    required this.onTap,
  });

  final String assetName;
  final int quantity;
  final bool glow;
  final bool claimed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      onPressed: onTap,
      child: Opacity(
        // Claimed still reads as "reached" (glow stays), just dimmed a
        // touch so an already-taken reward doesn't look identical to a
        // fresh, still-claimable one -- the spec only describes
        // locked-vs-unlocked visuals, not a claimed state, so this is a
        // reasoned addition, not from the spec itself.
        opacity: claimed ? 0.55 : 1,
        child: SizedBox(
          width: 96,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: glow
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.55), blurRadius: 20, spreadRadius: 4)],
                      )
                    : null,
                child: Image.asset(assetName, fit: BoxFit.contain),
              ),
              const SizedBox(height: 4),
              Text(
                'X$quantity',
                style: TextStyle(
                  color: glow ? Colors.white : const Color(0xFFC9AD8F),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  shadows: glow ? const [Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1))] : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaimAnimationSpec {
  const _ClaimAnimationSpec({required this.id, required this.assetName});
  final String id;
  final String assetName;
}

/// "La récompense s'affiche en plein milieu de l'écran en brillant, puis
/// disparaît rapidement vers la droite. Durée totale : 2 secondes."
class _ClaimAnimationOverlay extends StatefulWidget {
  const _ClaimAnimationOverlay({required this.spec, required this.onDone});

  final _ClaimAnimationSpec spec;
  final VoidCallback onDone;

  @override
  State<_ClaimAnimationOverlay> createState() => _ClaimAnimationOverlayState();
}

class _ClaimAnimationOverlayState extends State<_ClaimAnimationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
  ]).animate(_controller);
  late final Animation<double> _slideOut = TweenSequence([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 70),
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `Positioned` must sit directly under `Stack` with nothing but
    // Stateless/StatefulWidgets in between -- `IgnorePointer` is itself a
    // RenderObjectWidget, so it (and `AnimatedBuilder`'s inner content) has
    // to live *inside* the `Positioned.fill`, not wrap it.
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final screenWidth = MediaQuery.of(context).size.width;
            return Container(
              color: Colors.black.withOpacity(0.25 * (1 - _slideOut.value)),
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(_slideOut.value * screenWidth, 0),
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.8), blurRadius: 36, spreadRadius: 8)],
                    ),
                    child: Image.asset(widget.spec.assetName, fit: BoxFit.contain),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
