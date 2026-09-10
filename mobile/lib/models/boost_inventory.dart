import 'boost.dart';

/// Placeholder for "la réserve de bonus : quantités actuellement possédées
/// de chaque boost" (10-fiche-mission-niveau.md). There's no backend
/// inventory yet (`ProgressDTO` only carries lives/coins/xp), no way to
/// earn a boost (14-boutique.md isn't built), and no way to spend one
/// (11-ecran-de-jeu.md isn't built either) -- so every quantity is
/// honestly 0 rather than an invented number, until that whole loop
/// exists. A boost showing 0 reads as dimmed/unselectable on the mission
/// sheet, which is the truth right now.
class BoostInventory {
  BoostInventory._();

  static const Map<Boost, int> placeholder = {
    Boost.cafeLatte: 0,
    Boost.cafeAEmporter: 0,
    Boost.matchaLatte: 0,
    Boost.canetteSoda: 0,
    Boost.jusOrange: 0,
  };
}
