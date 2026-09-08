/// Base URL of the Railway-hosted backend. Replace once the backend is
/// deployed (see backend/README.md). Point this at the Railway staging
/// URL for debug builds and the production URL for release once both exist.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = 'https://coffee-break-backend.up.railway.app';
}
