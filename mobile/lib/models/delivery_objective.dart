/// The "delivery" level objective type, per 05-mecaniques-de-jeu.md: one or
/// more specific objects must travel from the top of the grid to the last
/// row, carried by gravity, with the player clearing obstacles blocking
/// their path. A level can use either object alone or both at once for
/// extra difficulty.
///
/// This only models the two deliverable objects and their assets. The
/// board engine exists now (11-ecran-de-jeu.md,
/// `lib/models/game_board.dart`), but delivery-style travel down the
/// board is deliberately deferred (see mobile/README.md) -- every cell
/// is still a plain `GameElement`.
enum DeliveryObjective {
  chantilly,
  sacDeCafe;

  String get assetName {
    switch (this) {
      case DeliveryObjective.chantilly:
        return 'assets/delivery_objectives/objectif-chantilly.png';
      case DeliveryObjective.sacDeCafe:
        return 'assets/delivery_objectives/objectif-sac-cafe.png';
    }
  }
}
