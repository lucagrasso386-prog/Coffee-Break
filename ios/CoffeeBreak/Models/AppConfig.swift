import Foundation

enum AppConfig {
    /// Base URL of the Railway-hosted backend. Replace once the backend is
    /// deployed (see backend/README.md). Point this at the Railway staging
    /// URL for Debug builds and production URL for Release once both exist.
    static let apiBaseURL = URL(string: "https://coffee-break-backend.up.railway.app")!
}
