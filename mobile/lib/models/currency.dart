/// The in-game coin currency, per 03-assets-de-jeu.md. Only one currency
/// exists so far, but this stays an enum for parity with GameElement/Boost
/// and to leave room if a second currency is added later.
enum Currency {
  coinCafe;

  String get assetName {
    switch (this) {
      case Currency.coinCafe:
        return 'assets/currency/coin-cafe.jpeg';
    }
  }
}
