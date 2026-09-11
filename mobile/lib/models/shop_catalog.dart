import 'boost.dart';
import 'currency.dart';

/// One granted item inside a starter pack's left/right slot. Exactly one of
/// [assetName]/[emoji] is set: [emoji] is only used for the two "boost
/// chrono"/"boost infini" grants in pack 3, which have no dedicated art and
/// no gameplay definition in any spec file reached so far -- the reference
/// mockup itself renders them as plain stopwatch/infinity glyphs rather
/// than commissioned art, so reusing that same plain-glyph treatment here
/// is following the source, not fabricating new content.
class PackItem {
  const PackItem({this.assetName, this.emoji, this.quantity}) : assert(assetName != null || emoji != null);

  final String? assetName;
  final String? emoji;

  /// Null when the mockup shows the icon without a printed number (every
  /// item in pack 3's left cluster, implicitly x1 each).
  final int? quantity;
}

/// 14-boutique.md 14.1: a real-money starter pack. Each pack has one
/// "headline" item on the left and one on the right (pack 3's left side is
/// a cluster of several items instead of just one, per the mockup).
class StarterPack {
  const StarterPack({required this.leftItems, required this.rightItem, required this.priceLabel});

  final List<PackItem> leftItems;
  final PackItem rightItem;
  final String priceLabel;
}

/// The 3 packs, reproducing the reference mockup's own icon choices:
/// pack 1's "café" is the to-go cup (`cafeAEmporter`), pack 2's is the mug
/// with heart latte art (`cafeLatte`) -- the spec text calls both just
/// "café", but the mockup draws them differently, so the art is what's
/// followed here. No "money bag" or "treasure chest" asset exists for the
/// bigger coin rewards (packs 2 and 3's right side) -- reusing the one real
/// coin asset (`Currency.coinCafe`), same precedent as
/// `reward_tier.dart`.
final List<StarterPack> starterPacks = [
  StarterPack(
    priceLabel: '3,99 €',
    leftItems: [PackItem(assetName: Currency.coinCafe.assetName, quantity: 350)],
    rightItem: PackItem(assetName: Boost.cafeAEmporter.assetName, quantity: 2),
  ),
  StarterPack(
    priceLabel: '9,99 €',
    leftItems: [PackItem(assetName: Boost.cafeLatte.assetName, quantity: 2)],
    rightItem: PackItem(assetName: Currency.coinCafe.assetName, quantity: 750),
  ),
  StarterPack(
    priceLabel: '22,99 €',
    leftItems: [
      PackItem(assetName: Boost.cafeAEmporter.assetName),
      PackItem(assetName: Boost.jusOrange.assetName),
      PackItem(assetName: Boost.cafeLatte.assetName),
      const PackItem(assetName: 'assets/hud/hud_heart.png'),
      const PackItem(emoji: '⏱️'),
      const PackItem(emoji: '♾️'),
    ],
    rightItem: PackItem(assetName: Currency.coinCafe.assetName, quantity: 1300),
  ),
];

/// 14.2: temporary boosts payable in in-game coins. "Outis surprise" is
/// reproduced verbatim from both the spec text and the mockup image --
/// almost certainly a typo for "Outils", but it's consistent across both
/// source files, so it's kept as given rather than silently "corrected."
/// All 4 last 1h and cost the same 2000 coins, per the mockup.
class TempBoostOffer {
  const TempBoostOffer({required this.label});
  final String label;
  int get priceCoins => 2000;
}

const List<TempBoostOffer> tempBoostOffers = [
  TempBoostOffer(label: 'Score x2'),
  TempBoostOffer(label: 'Vie illimitée'),
  TempBoostOffer(label: 'Bonus surprise'),
  TempBoostOffer(label: 'Outis surprise'),
];

/// 14.3: real-money coin-only packs. No visual "pile size" progression art
/// exists beyond the single coin sprite, so every row reuses it at the same
/// size -- only the printed quantity signals the size of the pack.
class CoinPack {
  const CoinPack({required this.quantity, required this.priceLabel});
  final int quantity;
  final String priceLabel;
}

const List<CoinPack> coinPacks = [
  CoinPack(quantity: 350, priceLabel: '1,99 €'),
  CoinPack(quantity: 700, priceLabel: '8,99 €'),
  CoinPack(quantity: 2500, priceLabel: '24,99 €'),
  CoinPack(quantity: 10500, priceLabel: '49,99 €'),
  CoinPack(quantity: 20000, priceLabel: '99,99 €'),
];
