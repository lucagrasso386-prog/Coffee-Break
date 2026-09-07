import Foundation

/// The 5 power-up visuals (boissons theme), per 03-assets-de-jeu.md.
/// Their effects/powers land with 06-pouvoirs-des-bonus.md.
enum Boost: String, CaseIterable {
    case cafeLatte
    case cafeAEmporter
    case matchaLatte
    case canetteSoda
    case jusOrange

    /// Matches the imageset name in Assets.xcassets/Boosts.
    var assetName: String {
        switch self {
        case .cafeLatte: return "boost-cafe-latte"
        case .cafeAEmporter: return "boost-cafe-a-emporter"
        case .matchaLatte: return "boost-matcha-latte"
        case .canetteSoda: return "boost-canette-soda"
        case .jusOrange: return "boost-jus-orange"
        }
    }
}
