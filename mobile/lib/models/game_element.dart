/// The 6 matchable elements, per 03-assets-de-jeu.md.
enum GameElement {
  cupcake,
  donut,
  tartelette,
  croissant,
  partGateau,
  bretzel;

  String get assetName {
    switch (this) {
      case GameElement.cupcake:
        return 'assets/game_elements/element-cupcake-glacage-chocolat.png';
      case GameElement.donut:
        return 'assets/game_elements/element-donut-glacage-rose.png';
      case GameElement.tartelette:
        return 'assets/game_elements/element-tartelette-fraise-chantilly.png';
      case GameElement.croissant:
        return 'assets/game_elements/element-croissant.png';
      case GameElement.partGateau:
        return 'assets/game_elements/element-part-gateau-couches.png';
      case GameElement.bretzel:
        return 'assets/game_elements/element-bretzel.png';
    }
  }
}
