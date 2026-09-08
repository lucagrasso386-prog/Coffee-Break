/// The 5 boost visuals, per 03-assets-de-jeu.md.
enum Boost {
  cafeLatte,
  cafeAEmporter,
  matchaLatte,
  canetteSoda,
  jusOrange;

  String get assetName {
    switch (this) {
      case Boost.cafeLatte:
        return 'assets/boosts/boost-cafe-latte.png';
      case Boost.cafeAEmporter:
        return 'assets/boosts/boost-cafe-a-emporter.png';
      case Boost.matchaLatte:
        return 'assets/boosts/boost-matcha-latte.png';
      case Boost.canetteSoda:
        return 'assets/boosts/boost-canette-soda.png';
      case Boost.jusOrange:
        return 'assets/boosts/boost-jus-orange.png';
    }
  }
}
