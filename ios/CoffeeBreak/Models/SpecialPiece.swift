import Foundation

/// The 3 special pieces created by aligning matchable elements, per
/// 05-mecaniques-de-jeu.md. Animations are all under 1 second.
///
/// Detecting which alignment pattern the player made and actually applying
/// the effect (bursts, line clears, 3x3 explosions) needs the match-3 board
/// engine, which doesn't exist yet -- that lands with the board/gameplay
/// code once 11-ecran-de-jeu.md is processed. This only captures the static
/// data: what creates each piece, its asset, and what it does in words.
enum SpecialPiece: String, CaseIterable {
    case tourbillon
    case bombeEclats
    /// Clears the column it's in when triggered. Visually the "vertical
    /// stripes" variant -- see rayeeHorizontale for the row-clearing one.
    /// (Row vs. column assignment isn't specified in 05-mecaniques-de-jeu.md
    /// itself; this follows the common match-3 convention where a
    /// horizontal 4-match yields a vertical-stripe/column-clear piece.)
    case rayeeVerticale
    /// Clears the row it's in when triggered. Visually the "horizontal
    /// stripes" variant.
    case rayeeHorizontale

    var assetName: String {
        switch self {
        case .tourbillon: return "special-tourbillon"
        case .bombeEclats: return "special-bombe-eclats"
        case .rayeeVerticale: return "special-rayee-verticale"
        case .rayeeHorizontale: return "special-rayee-horizontale"
        }
    }

    /// How the player creates this piece.
    var creationDescription: String {
        switch self {
        case .tourbillon: return "5 identical elements aligned in a line"
        case .bombeEclats: return "elements aligned in a T or L shape"
        case .rayeeVerticale, .rayeeHorizontale: return "4 identical elements aligned in a line (vertical or horizontal)"
        }
    }

    /// What happens when triggered.
    var effectDescription: String {
        switch self {
        case .tourbillon:
            return "spins and flings chocolate drops at random board elements; each drop hitting an element destroys it"
        case .bombeEclats:
            return "shakes twice, then explodes, destroying the 3x3 zone around it"
        case .rayeeVerticale:
            return "disappears, clearing the whole column"
        case .rayeeHorizontale:
            return "disappears, clearing the whole row"
        }
    }
}
