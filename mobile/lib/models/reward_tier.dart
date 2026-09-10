import 'boost.dart';
import 'currency.dart';

/// 13-ecran-recompenses.md: "30 000 XP nécessaires pour débloquer chaque
/// palier de récompense."
const int xpPerRewardTier = 30000;

/// One line item in a tier's reward bundle: a free (left column) quantity
/// and a premium/subscriber (right column) quantity of the same asset.
class RewardItem {
  const RewardItem({required this.assetName, required this.freeQuantity, required this.premiumQuantity});

  final String assetName;
  final int freeQuantity;
  final int premiumQuantity;
}

/// The reward bundle every tier grants, per the spec's own reference
/// mockup -- no "exemple" qualifier on this one (unlike the mission
/// sheet's level-1 example), so it's treated as the real, fixed bundle
/// reused at every tier rather than a one-off illustration. No "money
/// bag" asset exists for the x750 coin rewards shown larger in the
/// mockup -- reusing the one real coin asset (`Currency.coinCafe`) for
/// every coin line item rather than inventing a second coin sprite.
///
/// `final`, not `const`: built from the enums' own `assetName` getters
/// (not string literals duplicated here) so this can never drift out of
/// sync if those paths ever change.
final List<RewardItem> rewardTierBundle = [
  RewardItem(assetName: Currency.coinCafe.assetName, freeQuantity: 120, premiumQuantity: 750),
  RewardItem(assetName: Boost.cafeAEmporter.assetName, freeQuantity: 1, premiumQuantity: 3),
  RewardItem(assetName: Boost.jusOrange.assetName, freeQuantity: 1, premiumQuantity: 3),
  RewardItem(assetName: Currency.coinCafe.assetName, freeQuantity: 50, premiumQuantity: 750),
];
