import Foundation

/// The "delivery" level objective type, per 05-mecaniques-de-jeu.md: one or
/// more specific objects must travel from the top of the grid to the last
/// row, carried by gravity, with the player clearing obstacles blocking
/// their path. A level can use either object alone or both at once for
/// extra difficulty.
///
/// This only models the two deliverable objects and their assets; the
/// travel/gravity logic depends on the board engine (11-ecran-de-jeu.md).
enum DeliveryObjective: String, CaseIterable {
    case chantilly
    case sacDeCafe

    var assetName: String {
        switch self {
        case .chantilly: return "objectif-chantilly"
        case .sacDeCafe: return "objectif-sac-cafe"
        }
    }
}
