part of '../shop_ui.dart';

/// One responsive, accessible sneaker card across catalog / wishlist / stores.
/// Hover reveals a quick-view cue; tapping the whole card works on touch.
class ProductTile extends StatefulWidget {
  const ProductTile({
    super.key,
    required this.product,
    this.storeId,
    this.onOpen,
  });
  final Json product;
  final int? storeId;
  final VoidCallback? onOpen;

  @override
  State<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  bool _hovered = false;

  void _open() {
    if (widget.onOpen != null) {
      widget.onOpen!();
      return;
    }
    Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<ShopCubit>(),
        child: ProductPage(
          productId: widget.product['id'] as int,
          storeId: widget.storeId),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final p = widget.product;
    final favorite = cubit.state.favorites.contains(p['id']);
    final sale = (p['discount'] as int) > 0;
    final stock = Map<String, dynamic>.from(p['sizes'] as Map);
    final count = stock.values.fold<int>(0, (sum, n) => sum + (n as num).toInt());
    final low = stock.values.any((n) {
      final quantity = (n as num).toInt();
      return quantity > 0 && quantity <= 2;
    });
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: _hovered
              ? SneakerDesign.ink : Theme.of(context).dividerColor,
            width: _hovered ? 1.4 : .8)),
        child: InkWell(
          onTap: _open,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(
                  color: SneakerDesign.imageSurface,
                  // Every product photo fills the same card frame regardless
                  // of whether the source is portrait, square or landscape.
                  // Crop excess edges rather than shrinking the whole photo.
                  child: ClipRect(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      scale: _hovered ? 1.05 : 1,
                      child: Image.network(
                        p['image_url'] as String,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.image_not_supported_outlined,
                            color: SneakerDesign.muted, size: 36),
                        ),
                      ),
                    ),
                  ),
                ),
                if (sale)
                  Positioned(top: 12, left: 11,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: SneakerDesign.ink,
                        borderRadius: BorderRadius.circular(3)),
                      child: Text('-${p['discount']}%',
                        style: const TextStyle(
                          color: SneakerDesign.lime, fontSize: 11,
                          letterSpacing: .6, fontWeight: FontWeight.w900)),
                    )),
                Positioned(top: 7, right: 7, child: Material(
                  shape: const CircleBorder(), color: Colors.white,
                  child: IconButton(
                    iconSize: 20,
                    tooltip: favorite ? 'Remove from saved' : 'Save this sneaker',
                    icon: Icon(favorite
                      ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: favorite
                        ? const Color(0xFFD94C4C) : SneakerDesign.ink),
                    onPressed: () => cubit.toggleFavorite(p['id'] as int),
                  ),
                )),
                if (_hovered)
                  Positioned(left: 12, bottom: 12, right: 12,
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: SneakerDesign.lime,
                        borderRadius: BorderRadius.circular(3)),
                      alignment: Alignment.center,
                      child: const Text('VIEW SNEAKER  ↗',
                        style: TextStyle(color: SneakerDesign.ink,
                          fontSize: 11, fontWeight: FontWeight.w900,
                          letterSpacing: .8)),
                    )),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 13, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((p['brand'] as String).toUpperCase(),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 1.3)),
                  const SizedBox(height: 5),
                  Text(p['name'] as String,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w900, letterSpacing: -.2)),
                  const SizedBox(height: 9),
                  Row(children: [
                    Expanded(child: Text(money(amount(p)),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900,
                        fontSize: 14))),
                    const Icon(Icons.arrow_outward,
                      color: SneakerDesign.ink, size: 17),
                  ]),
                  if (sale)
                    Text(money(p['price_cents'] as int),
                      style: TextStyle(fontSize: 11, color: muted,
                        decoration: TextDecoration.lineThrough)),
                  if (widget.storeId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(count == 0 ? 'SOLD OUT  ·  GET NOTIFIED'
                          : low ? 'LIMITED SIZES IN STOCK'
                            : '$count PAIRS AT THIS STORE',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: count == 0 || low
                            ? const Color(0xFFAD5015) : muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35)),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
