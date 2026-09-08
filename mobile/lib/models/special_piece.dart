/// The 3 special pieces created by aligning matchable elements, per
/// 05-mecaniques-de-jeu.md. Animations are all under 1 second.
///
/// Detecting which alignment pattern the player made and actually applying
/// the effect (bursts, line clears, 3x3 explosions) needs the match-3 board
/// engine, which doesn't exist yet -- that lands with the board/gameplay
/// code once 11-ecran-de-jeu.md is processed. This only captures the static
/// data: what creates each piece, its asset, and what it does in words.
enum SpecialPiece {
  tourbillon,
  bombeEclats,

  /// Clears the column it's in when triggered. Visually the "vertical
  /// stripes" variant -- see rayeeHorizontale for the row-clearing one.
  /// (Row vs. column assignment isn't specified in 05-mecaniques-de-jeu.md
  /// itself; this follows the common match-3 convention where a
  /// horizontal 4-match yields a vertical-stripe/column-clear piece.)
  rayeeVerticale,

  /// Clears the row it's in when triggered. Visually the "horizontal
  /// stripes" variant.
  rayeeHorizontale;

  String get assetName {
    switch (this) {
      case SpecialPiece.tourbillon:
        return 'assets/special_pieces/special-tourbillon.png';
      case SpecialPiece.bombeEclats:
        return 'assets/special_pieces/special-bombe-eclats.png';
      case SpecialPiece.rayeeVerticale:
        return 'assets/special_pieces/special-rayee-verticale.png';
      case SpecialPiece.rayeeHorizontale:
        return 'assets/special_pieces/special-rayee-horizontale.png';
    }
  }

  /// How the player creates this piece.
  String get creationDescription {
    switch (this) {
      case SpecialPiece.tourbillon:
        return '5 identical elements aligned in a line';
      case SpecialPiece.bombeEclats:
        return 'elements aligned in a T or L shape';
      case SpecialPiece.rayeeVerticale:
      case SpecialPiece.rayeeHorizontale:
        return '4 identical elements aligned in a line (vertical or horizontal)';
    }
  }

  /// What happens when triggered.
  String get effectDescription {
    switch (this) {
      case SpecialPiece.tourbillon:
        return 'spins and flings chocolate drops at random board elements; each drop hitting an element destroys it';
      case SpecialPiece.bombeEclats:
        return 'shakes twice, then explodes, destroying the 3x3 zone around it';
      case SpecialPiece.rayeeVerticale:
        return 'disappears, clearing the whole column';
      case SpecialPiece.rayeeHorizontale:
        return 'disappears, clearing the whole row';
    }
  }
}
