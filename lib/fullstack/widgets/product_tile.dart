part of '../shop_ui.dart';

class ProductTile extends StatelessWidget {
  final Json product;
  final int? storeId;
  final VoidCallback? onOpen;
  const ProductTile({super.key, required this.product, this.storeId, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final isFavorite = cubit.state.favorites.contains(product['id']);
    final discount = (product['discount'] as int);
    final sizes = Map<String, dynamic>.from(product['sizes'] as Map);
    final count = sizes.values.fold<int>(0, (n, item) => n + (item as num).toInt());
    final lowStock = storeId != null && count > 0 &&
      sizes.values.any((item) {
        final quantity = (item as num).toInt();
        return quantity > 0 && quantity <= 2;
      });
    void open() {
      if (onOpen != null) {
        onOpen!();
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) =>
        BlocProvider.value(value: context.read<ShopCubit>(),
          child: ProductPage(
            productId: product['id'] as int, storeId: storeId))));
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: Stack(fit: StackFit.expand, children: [
            ColoredBox(
              color: SneakerDesign.imageSurface,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: photo(product['image_url'] as String, height: 230)),
            ),
            if (discount > 0)
              Positioned(top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: SneakerDesign.orange,
                    borderRadius: BorderRadius.circular(9)),
                  child: Text('-$discount%',
                    style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 11)))),
            Positioned(top: 8, right: 8,
              child: Material(
                color: Colors.white, shape: const CircleBorder(),
                child: IconButton(
                  tooltip: isFavorite ? 'Remove from favorites' : 'Save to favorites',
                  icon: Icon(isFavorite ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded, size: 20,
                    color: isFavorite ? SneakerDesign.orange : SneakerDesign.ink),
                  onPressed: () => cubit.toggleFavorite(product['id'] as int),
                ),
              )),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((product['brand'] as String).toUpperCase(),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, letterSpacing: 1.2,
                  fontWeight: FontWeight.bold, color: SneakerDesign.muted)),
              const SizedBox(height: 5),
              Text(product['name'] as String,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text(money(amount(product)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                const Icon(Icons.arrow_outward_rounded, size: 17,
                  color: SneakerDesign.muted),
              ]),
              if (discount > 0)
                Text(money(product['price_cents'] as int),
                  style: const TextStyle(fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                    color: SneakerDesign.muted)),
              if (storeId != null)
                Padding(padding: const EdgeInsets.only(top: 5),
                  child: Text(count == 0 ? 'Sold out • Notify me'
                    : lowStock ? 'Some sizes almost gone' : '$count in this store',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: count == 0 || lowStock
                        ? SneakerDesign.orange : SneakerDesign.muted))),
            ]),
          ),
        ]),
      ),
    );
  }
}
