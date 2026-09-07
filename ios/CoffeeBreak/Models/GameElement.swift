import Foundation

/// The 6 matchable elements (pâtisserie theme), per 03-assets-de-jeu.md.
/// Match-3 board mechanics land with 05-mecaniques-de-jeu.md.
enum GameElement: String, CaseIterable {
    case cupcakeGlacageChocolat
    case donutGlacageRose
    case tarteletteFraiseChantilly
    case croissant
    case partGateauCouches
    case bretzel

    /// Matches the imageset name in Assets.xcassets/GameElements.
    var assetName: String {
        switch self {
        case .cupcakeGlacageChocolat: return "element-cupcake-glacage-chocolat"
        case .donutGlacageRose: return "element-donut-glacage-rose"
        case .tarteletteFraiseChantilly: return "element-tartelette-fraise-chantilly"
        case .croissant: return "element-croissant"
        case .partGateauCouches: return "element-part-gateau-couches"
        case .bretzel: return "element-bretzel"
        }
    }
}
