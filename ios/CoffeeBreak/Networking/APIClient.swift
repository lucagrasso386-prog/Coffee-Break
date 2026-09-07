import Foundation

struct ProgressDTO: Codable {
    let unlockedLevel: Int
    let xp: Int
    let coins: Int
}

struct AuthResponse: Codable {
    let userId: String
    let token: String
    let progress: ProgressDTO?
}

enum APIError: Error {
    case invalidResponse
    case server(status: Int)
}

/// Thin wrapper around the backend REST API. See backend/README.md for the
/// endpoint list.
final class APIClient {
    static let shared = APIClient()

    private let baseURL = AppConfig.apiBaseURL
    private let session = URLSession.shared
    private var sessionToken: String? {
        get { UserDefaults.standard.string(forKey: "coffeebreak.sessionToken") }
        set { UserDefaults.standard.set(newValue, forKey: "coffeebreak.sessionToken") }
    }

    private init() {}

    /// Creates/loads the device-local account. Call this on first launch
    /// before any other authenticated request, if the player hasn't
    /// connected a real account.
    func authenticateWithDevice() async throws -> AuthResponse {
        let response: AuthResponse = try await post("/auth/device", body: ["deviceId": DeviceIdentity.current])
        sessionToken = response.token
        return response
    }

    /// Sign in with Apple. Pass `linkDeviceId` to attach the current
    /// device-local account's progress to the Apple ID instead of loading a
    /// separate Apple-linked account.
    func authenticateWithApple(identityToken: String, linkDeviceId: String? = nil) async throws -> AuthResponse {
        var body: [String: String] = ["identityToken": identityToken]
        if let linkDeviceId {
            body["linkDeviceId"] = linkDeviceId
        }
        let response: AuthResponse = try await post("/auth/apple", body: body)
        sessionToken = response.token
        return response
    }

    func fetchProgress() async throws -> ProgressDTO? {
        struct Wrapper: Codable { let progress: ProgressDTO? }
        let wrapper: Wrapper = try await get("/progress")
        return wrapper.progress
    }

    // MARK: - Low-level helpers

    private func get<Response: Decodable>(_ path: String) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "GET"
        return try await send(request)
    }

    private func post<Response: Decodable>(_ path: String, body: [String: String]) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        var request = request
        if let sessionToken {
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.server(status: http.statusCode)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
