import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_config.dart';
import '../models/device_identity.dart';

class ProgressDTO {
  final int unlockedLevel;
  final int xp;
  final int coins;
  final int lives;
  final DateTime livesUpdatedAt;

  ProgressDTO({
    required this.unlockedLevel,
    required this.xp,
    required this.coins,
    required this.lives,
    required this.livesUpdatedAt,
  });

  factory ProgressDTO.fromJson(Map<String, dynamic> json) => ProgressDTO(
        unlockedLevel: json['unlockedLevel'] as int,
        xp: json['xp'] as int,
        coins: json['coins'] as int,
        lives: json['lives'] as int,
        livesUpdatedAt: DateTime.parse(json['livesUpdatedAt'] as String),
      );
}

class AuthResponse {
  final String userId;
  final String token;
  final ProgressDTO? progress;

  AuthResponse({required this.userId, required this.token, this.progress});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        userId: json['userId'] as String,
        token: json['token'] as String,
        progress: json['progress'] == null
            ? null
            : ProgressDTO.fromJson(json['progress'] as Map<String, dynamic>),
      );
}

class ApiException implements Exception {
  final int status;
  ApiException(this.status);

  @override
  String toString() => 'ApiException(status: $status)';
}

/// Thin wrapper around the backend REST API. See backend/README.md for the
/// endpoint list.
class ApiClient {
  ApiClient._();
  static final ApiClient shared = ApiClient._();

  static const String _tokenKey = 'coffeebreak.sessionToken';
  final Uri _baseUrl = Uri.parse(AppConfig.apiBaseUrl);
  final http.Client _http = http.Client();

  Future<String?> get _sessionToken async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<void> _setSessionToken(String token) async {
    await (await SharedPreferences.getInstance()).setString(_tokenKey, token);
  }

  /// Creates/loads the device-local account. Call this on first launch
  /// before any other authenticated request, if the player hasn't
  /// connected a real account.
  Future<AuthResponse> authenticateWithDevice() async {
    final deviceId = await DeviceIdentity.current();
    final response = AuthResponse.fromJson(
      await _post('/auth/device', {'deviceId': deviceId}),
    );
    await _setSessionToken(response.token);
    return response;
  }

  /// Sign in with Apple. Pass [linkDeviceId] to attach the current
  /// device-local account's progress to the Apple ID instead of loading a
  /// separate Apple-linked account.
  Future<AuthResponse> authenticateWithApple(
    String identityToken, {
    String? linkDeviceId,
  }) async {
    final body = <String, String>{'identityToken': identityToken};
    if (linkDeviceId != null) body['linkDeviceId'] = linkDeviceId;
    final response = AuthResponse.fromJson(await _post('/auth/apple', body));
    await _setSessionToken(response.token);
    return response;
  }

  /// Sign in with Google -- the Android-launch counterpart to Apple sign-in
  /// (backend/src/routes/auth.ts POST /auth/google). Pass [linkDeviceId] to
  /// attach the current device-local account's progress to the Google
  /// account instead of loading a separate Google-linked account.
  Future<AuthResponse> authenticateWithGoogle(
    String idToken, {
    String? linkDeviceId,
  }) async {
    final body = <String, String>{'idToken': idToken};
    if (linkDeviceId != null) body['linkDeviceId'] = linkDeviceId;
    final response = AuthResponse.fromJson(await _post('/auth/google', body));
    await _setSessionToken(response.token);
    return response;
  }

  Future<ProgressDTO?> fetchProgress() async {
    final wrapper = await _get('/progress');
    final progress = wrapper['progress'];
    return progress == null ? null : ProgressDTO.fromJson(progress as Map<String, dynamic>);
  }

  /// Reports a finished level so the server can apply the XP reward
  /// (04-systemes-progression-et-xp.md). Not called from any screen yet.
  Future<(ProgressDTO progress, int xpGained)> completeLevel({
    required int stars,
    required int movesRemaining,
  }) async {
    final wrapper = await _post('/progress/complete-level', {
      'stars': stars,
      'movesRemaining': movesRemaining,
    });
    return (
      ProgressDTO.fromJson(wrapper['progress'] as Map<String, dynamic>),
      wrapper['xpGained'] as int,
    );
  }

  /// Spends one life. Not called from any screen yet -- the trigger
  /// (level start vs. loss) isn't defined until later spec files.
  Future<ProgressDTO> consumeLife() async {
    final wrapper = await _post('/progress/consume-life', {});
    return ProgressDTO.fromJson(wrapper['progress'] as Map<String, dynamic>);
  }

  // MARK: - Low-level helpers

  Future<Map<String, dynamic>> _get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _baseUrl.resolve(path);
    final token = await _sessionToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = method == 'GET'
        ? await _http.get(uri, headers: headers)
        : await _http.post(uri, headers: headers, body: jsonEncode(body ?? {}));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
