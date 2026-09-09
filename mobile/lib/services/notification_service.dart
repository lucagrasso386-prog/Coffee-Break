import 'package:firebase_messaging/firebase_messaging.dart';

/// Push notification permission + registration, per 07-regles-globales-ui.md:
/// "Le joueur doit être sollicité pour autoriser les notifications" for all
/// game events (lives refilled, ongoing events, etc.).
///
/// Needs `Firebase.initializeApp()` called first (e.g. at the top of
/// `main()`), which in turn needs a real Firebase project's
/// `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) --
/// neither exists yet, see docs/SETUP.md. Not called from `main.dart` yet
/// for that reason: calling it without those config files present would
/// crash on startup instead of just no-op-ing.
///
/// What triggers an actual notification (lives refilled, an event
/// starting, ...) is server-side work this doesn't cover -- sending pushes
/// needs the Firebase Admin SDK wired into the backend plus somewhere to
/// store each user's token, neither of which exist yet either. This is
/// just the client half: ask permission, get a token.
class NotificationService {
  NotificationService._();

  /// Prompts the player to allow notifications (the OS permission dialog).
  /// Returns true if granted. Safe to call more than once -- iOS/Android
  /// both just re-report the current status after the first real prompt.
  static Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// The device's current push token, or null if notifications aren't
  /// permitted yet or a token isn't available. Sending this to the backend
  /// so it can actually target this device is not wired up yet -- there's
  /// no endpoint to send it to.
  static Future<String?> currentToken() => FirebaseMessaging.instance.getToken();
}
