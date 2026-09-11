import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../models/shop_catalog.dart';
import '../widgets/coming_soon_screen.dart';
import '../widgets/spring_button.dart';

/// 14-boutique.md: the shop, reached from the map's HUD shop icon (and, per
/// 12-popups-fin-de-niveau.md, from the lost popup's "Rejouer" when out of
/// lives). "Pas de bouton retour, uniquement swipe gauche/droite pour
/// quitter" is enforced the same way as `rewards_screen.dart`:
/// `PopScope(canPop: false)` blocks the system back gesture, and only this
/// screen's own horizontal swipe can leave.
///
/// No IAP plugin is wired into this project yet (nothing in
/// `pubspec.yaml`), and the backend's `POST /iap/validate-receipt`
/// (`backend/src/routes/iap.ts`) still can't verify a real Apple/Google
/// receipt or credit anything -- every priced button here is an honest
/// `ComingSoonScreen` stub rather than a payment flow that can't actually
/// complete.
const _brown = Color(0xFF6B4226);
const _shopBackground = Color(0xFF8A6A50);
const _pink = Color(0xFFE85D9E);
const _green = Color(0xFF7CB342);
const _cyan = Color(0xFF3FE0FF);

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _showMore = false;

  void _onHorizontalSwipe(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond.dx;
    if (v.abs() > 250) Navigator.of(context).pop();
  }

  void _buyWithMoney(BuildContext context, String priceLabel) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComingSoonScreen(
        message: 'Le paiement natif ($priceLabel) n\'est pas encore intégré -- '
            "aucun SDK d'achat intégré (StoreKit/Google Play Billing) dans le "
            "projet, et la validation de reçu côté serveur "
            '(backend/src/routes/iap.ts) attend encore le catalogue de '
            'produits réel.',
      ),
    ));
  }

  void _buyWithCoins(BuildContext context, TempBoostOffer offer) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComingSoonScreen(
        message: '"${offer.label}" n\'est pas encore activable -- ni la dépense de '
            'pièces, ni l\'effet du boost temporaire lui-même n\'ont de système '
            'réel pour le moment.',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _shopBackground,
        body: GestureDetector(
          onHorizontalDragEnd: _onHorizontalSwipe,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  for (final pack in starterPacks) ...[
                    _PackRow(pack: pack, onBuy: () => _buyWithMoney(context, pack.priceLabel)),
                    const SizedBox(height: 18),
                  ],
                  if (!_showMore)
                    _PillButton(
                      label: 'VOIR PLUS',
                      color: const Color(0xFFE8A0B8),
                      onPressed: () => setState(() => _showMore = true),
                    ),
                  if (_showMore) ...[
                    for (final offer in tempBoostOffers) ...[
                      _TempBoostRow(offer: offer, onBuy: () => _buyWithCoins(context, offer)),
                      const SizedBox(height: 14),
                    ],
                    _CoinVaultBanner(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const _CoinPacksScreen()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One starter-pack row: a left slot (one icon, or pack 3's cluster of
/// several), a right slot (always one bigger reward), and the pink price
/// button between them.
class _PackRow extends StatelessWidget {
  const _PackRow({required this.pack, required this.onBuy});

  final StarterPack pack;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF3FB6AE), width: 4),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              pack.leftItems.length == 1
                  ? _PackItemIcon(item: pack.leftItems.single, size: 56)
                  : _PackItemCluster(items: pack.leftItems),
              _PackItemIcon(item: pack.rightItem, size: 56),
            ],
          ),
          const SizedBox(height: 14),
          SpringButton(
            onPressed: onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                color: _pink,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                pack.priceLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackItemIcon extends StatelessWidget {
  const _PackItemIcon({required this.item, required this.size});

  final PackItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: item.assetName != null
              ? Image.asset(item.assetName!, fit: BoxFit.contain)
              : Center(child: Text(item.emoji!, style: TextStyle(fontSize: size * 0.7))),
        ),
        if (item.quantity != null) ...[
          const SizedBox(height: 4),
          Text('${item.quantity}', style: const TextStyle(color: _brown, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ],
    );
  }
}

/// Pack 3's left side: several small items with no individual quantity,
/// wrapped into a compact grid rather than one big icon.
class _PackItemCluster extends StatelessWidget {
  const _PackItemCluster({required this.items});

  final List<PackItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [for (final item in items) _PackItemIcon(item: item, size: 34)],
      ),
    );
  }
}

/// 14.2's temporary-boost row: label, "1h" duration, and a green-bordered
/// coin price (green rather than 14.1's pink pills, matching the mockup's
/// own distinct color for "payable in in-game coins" vs. "payable in real
/// money").
class _TempBoostRow extends StatelessWidget {
  const _TempBoostRow({required this.offer, required this.onBuy});

  final TempBoostOffer offer;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFFDD9CAE), borderRadius: BorderRadius.circular(28)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${offer.label} ⏱️ 1h',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          SpringButton(
            onPressed: onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF9BB86E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _green, width: 2),
              ),
              child: Text(
                '${offer.priceCoins}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The unlabeled treasure-chest "20 000" row at the bottom of 14.2's
/// mockup -- it carries no price and isn't one of the 4 offers the spec
/// text actually lists, so it's read here as a banner into 14.3 (buy more
/// coins with real money) rather than a 5th temporary boost. Not confirmed
/// with the creator; flagged in `mobile/README.md`.
class _CoinVaultBanner extends StatelessWidget {
  const _CoinVaultBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFDD9CAE), borderRadius: BorderRadius.circular(28)),
        child: Row(
          children: [
            Image.asset(Currency.coinCafe.assetName, width: 40, height: 40, fit: BoxFit.contain),
            const SizedBox(width: 12),
            const Text('20 000', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.color, required this.onPressed});

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SpringButton(
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3))],
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
          ),
        ),
      ),
    );
  }
}

/// 14.3: real-money coin-only packs, its own screen (per the spec's own
/// "Bouton Retour : revient à la boutique principale" -- implying this is
/// somewhere separate from it, not just further down the same scroll).
/// Reached by tapping the vault banner above.
class _CoinPacksScreen extends StatelessWidget {
  const _CoinPacksScreen();

  void _buy(BuildContext context, CoinPack pack) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComingSoonScreen(
        message: 'Le paiement natif (${pack.priceLabel}) n\'est pas encore intégré -- '
            "même limitation que la boutique principale : aucun SDK d'achat, "
            'pas encore de catalogue de produits côté serveur.',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _shopBackground,
        body: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.velocity.pixelsPerSecond.dx.abs() > 250) Navigator.of(context).pop();
          },
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  for (final pack in coinPacks) ...[
                    _CoinPackRow(pack: pack, onBuy: () => _buy(context, pack)),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  _PillButton(label: 'RETOUR', color: _brown, onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinPackRow extends StatelessWidget {
  const _CoinPackRow({required this.pack, required this.onBuy});

  final CoinPack pack;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFFDD9CAE), borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          Image.asset(Currency.coinCafe.assetName, width: 44, height: 44, fit: BoxFit.contain),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${pack.quantity}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ),
          SpringButton(
            onPressed: onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3A8FA0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cyan, width: 2),
              ),
              child: Text(
                pack.priceLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
