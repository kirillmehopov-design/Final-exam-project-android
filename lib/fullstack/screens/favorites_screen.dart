part of '../shop_ui.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ShopCubit>().state;
    final saved = s.products.where((p) => s.favorites.contains(p['id'])).toList();
    if (saved.isEmpty) return const Center(child: Text('No favorites yet. Tap hearts in the shop.'));
    return LayoutBuilder(builder: (context, box) => GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: box.maxWidth > 800 ? 4 : box.maxWidth > 500 ? 3 : 2,
        childAspectRatio: .75, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: saved.length,
      itemBuilder: (context, i) => ProductTile(product: saved[i]),
    ));
  }
}
