import 'boost.dart';

/// Up to this many boosts can be equipped for a level, chosen on the
/// mission sheet before play starts (`10-fiche-mission-niveau.md`, not
/// built yet). Not enforced anywhere yet -- there's no mission sheet
/// screen or loadout state to enforce it in.
const int maxEquippedBoosts = 5;

/// How the player targets a boost when activating it, per
/// 06-pouvoirs-des-bonus.md. The actual targeting UI (tapping a column,
/// tapping a board element, the off-board destination wheel for jus
/// d'orange) doesn't exist yet -- that's screen/interaction work for
/// 11-ecran-de-jeu.md. This only captures which shape of input each boost
/// needs once that screen exists.
enum BoostTargeting {
  /// Player taps a column; no element/type selection.
  column,

  /// Player taps a single board element or obstacle.
  boardElement,

  /// Player taps a board element to pick an element *type* (every element
  /// of that kind on the board), not just the one tapped piece.
  elementType,

  /// No target at all -- the effect applies immediately across the board.
  none,

  /// Two steps: tap a board element to pick the source type, then tap a
  /// destination icon in an off-board wheel/row of the other types present
  /// (not a second tap on the board).
  sourceThenOffBoardDestination,
}

/// Boost activation behavior, per 06-pouvoirs-des-bonus.md. Activation is
/// manual (the player triggers it in-level, it's not automatic), and all
/// five effects described here need the match-3 board engine to actually
/// run -- that's `11-ecran-de-jeu.md`. This only captures targeting and
/// effect as static data, same as SpecialPiece/Obstacle in
/// 05-mecaniques-de-jeu.md.
extension BoostPower on Boost {
  BoostTargeting get targeting {
    switch (this) {
      case Boost.cafeLatte:
        return BoostTargeting.column;
      case Boost.cafeAEmporter:
        return BoostTargeting.boardElement;
      case Boost.matchaLatte:
        return BoostTargeting.elementType;
      case Boost.canetteSoda:
        return BoostTargeting.none;
      case Boost.jusOrange:
        return BoostTargeting.sourceThenOffBoardDestination;
    }
  }

  /// What happens once the target (if any) is chosen.
  String get effectDescription {
    switch (this) {
      case Boost.cafeLatte:
        return 'coffee pours out at the top of the chosen column and flows '
            'down with gravity, destroying every element in the column on '
            'its way down';
      case Boost.cafeAEmporter:
        return 'acts like a hammer: removes the tapped element or obstacle '
            'directly, no match required';
      case Boost.matchaLatte:
        return 'multicolored shooting stars travel from the tapped point to '
            'every element of the chosen type on the board, each one '
            'turning into a random special piece (tourbillon, bombe aux '
            'éclats, or rayée -- rolled independently per element)';
      case Boost.canetteSoda:
        return 'bursts into a spray of bubbles that scatter across the '
            'whole board; each bubble triggers a small chain explosion on '
            'the element it lands on';
      case Boost.jusOrange:
        return 'a glitter-edged wave of orange juice spreads across the '
            'whole board, turning every element of the source type into '
            'the destination type as the wave passes over it';
    }
  }
}
