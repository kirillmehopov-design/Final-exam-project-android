part of '../shop_ui.dart';

class ProductTile extends StatelessWidget {
  final Json product;
  const ProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.watch<ShopCubit>().state.favorites.contains(product['id']);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => BlocProvider.value(
            value: context.read<ShopCubit>(),
            child: ProductPage(productId: product['id'] as int)))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Stack(fit: StackFit.expand, children: [
            photo(product['image_url'] as String, height: 220),
            if ((product['discount'] as int) > 0)
              Positioned(top: 8, left: 8, child: Chip(label: Text('-${product['discount']}%'))),
            Positioned(top: 3, right: 3, child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black),
                onPressed: () => context.read<ShopCubit>().toggleFavorite(product['id'] as int)),
            )),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name'] as String, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(product['brand'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(money(amount(product)),
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF243A76))),
            ])),
        ]),
      ),
    );
  }
}
