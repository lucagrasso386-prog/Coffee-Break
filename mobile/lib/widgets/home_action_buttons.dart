import 'package:flutter/material.dart';

import 'spring_button.dart';

/// The "PLAY" and "SE CONNECTER" buttons from 08-page-accueil.md, cropped
/// directly out of the validated mockup (`images/page-accueil.jpg`) rather
/// than rebuilt in code, so the exact painted bevel/highlight is preserved.
/// See `mobile/README.md` for how the crop was done.
///
/// Both just wrap the button art with [SpringButton] for the press/spring
/// feedback required of every button (07-regles-globales-ui.md); wire the
/// actual "load local progress" / "open sign-in" behavior in [onPressed].
class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      onPressed: onPressed,
      child: Image.asset('assets/ui/button_play.png'),
    );
  }
}

class SignInButton extends StatelessWidget {
  const SignInButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      onPressed: onPressed,
      child: Image.asset('assets/ui/button_se_connecter.png'),
    );
  }
}
