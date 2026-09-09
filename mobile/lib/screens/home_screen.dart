import 'package:flutter/material.dart';

import '../models/day_night_period.dart';
import '../networking/api_client.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/home_action_buttons.dart';
import 'progression_map_screen.dart';

/// 08-page-accueil.md: the app's home screen, which also serves as its
/// loading screen (never showing the word "chargement" itself).
///
/// Appear sequence per the spec: the background shows alone first while
/// the app loads, then shortly after, the logo slides in from the left at
/// the same time the buttons slide in from the right.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _buttonsSlide;
  late final String _backgroundAsset;

  static const _revealDelay = Duration(milliseconds: 350);
  static const _revealDuration = Duration(milliseconds: 450);

  static const Map<DayNightPeriod, String> _backgroundByPeriod = {
    DayNightPeriod.day: 'assets/home/home_background_day.jpg',
    DayNightPeriod.goldenHour: 'assets/home/home_background_golden.jpg',
    DayNightPeriod.night: 'assets/home/home_background_night.jpg',
  };

  @override
  void initState() {
    super.initState();
    // Fixed once per screen instance -- picking again mid-session (e.g.
    // on every animation frame's rebuild) would be wasteful and could
    // flip the background under the player's thumb right at the hour
    // boundary.
    _backgroundAsset = _backgroundByPeriod[DayNightSchedule.current()]!;
    _controller = AnimationController(vsync: this, duration: _revealDuration);
    _logoSlide = Tween<Offset>(begin: const Offset(-1.6, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _buttonsSlide = Tween<Offset>(begin: const Offset(1.6, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(_revealDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePlay() async {
    try {
      // Establishes the device-local account session so the progression
      // map can fetch real progress; offline/no-backend-yet is fine, the
      // map just falls back to "nothing validated" in that case.
      await ApiClient.shared.authenticateWithDevice();
    } catch (_) {
      // Ignored -- see above.
    }
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ProgressionMapScreen(),
    ));
  }

  void _handleSignIn() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ComingSoonScreen(
        message: "L'écran de connexion n'est pas encore spécifié.",
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _backgroundAsset,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: h * 0.1186,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _logoSlide,
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.576,
                      child: Image.asset(
                        'assets/branding/logo_coffee_break.png',
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: h * 0.1229,
                child: SlideTransition(
                  position: _buttonsSlide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.365,
                        child: PlayButton(onPressed: _handlePlay),
                      ),
                      SizedBox(height: h * 0.008),
                      FractionallySizedBox(
                        widthFactor: 0.370,
                        child: SignInButton(onPressed: _handleSignIn),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
