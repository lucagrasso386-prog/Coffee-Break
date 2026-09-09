import 'package:flutter/material.dart';

import '../models/device_identity.dart';
import '../widgets/home_action_buttons.dart';

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

  static const _revealDelay = Duration(milliseconds: 350);
  static const _revealDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
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
    await DeviceIdentity.current();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const _ComingSoonScreen(
        message: 'Le plateau de jeu arrive avec 11-ecran-de-jeu.md.',
      ),
    ));
  }

  void _handleSignIn() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const _ComingSoonScreen(
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
                'assets/home/home_background.jpg',
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

/// Stand-in destination for "PLAY" / "SE CONNECTER" until the game screen
/// (`11-ecran-de-jeu.md`) and a sign-in screen exist. Deliberately minimal.
class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Break')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
