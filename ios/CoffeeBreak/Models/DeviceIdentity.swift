import Foundation

/// Stable id for the device-local account, stored in UserDefaults (not
/// Keychain) on purpose: UserDefaults is wiped on uninstall, which is what
/// makes an uninstall/reinstall restart progress from zero for players who
/// never connected an account, per 01-setup-projet-et-architecture.md.
enum DeviceIdentity {
    private static let key = "coffeebreak.deviceId"

    static var current: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }
}
