part of '../shop_ui.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopCubit>().state;
    final saved = state.products
        .where((product) => state.favorites.contains(product['id'])).toList();
    if (saved.isEmpty) {
      return Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 90, height: 90,
            decoration: const BoxDecoration(
              color: SneakerDesign.lime, shape: BoxShape.circle),
            child: const Icon(Icons.favorite_border, size: 42)),
          const SizedBox(height: 23),
          const Text('Nothing saved. Yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          const Text('Tap the heart on any sneaker to keep it in your edit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SneakerDesign.muted)),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => context.read<ShopCubit>().selectTab(0),
            icon: const Icon(Icons.arrow_outward),
            label: const Text('EXPLORE SNEAKERS'),
          ),
        ]),
      ));
    }
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final padding = width < 500 ? 16.0 : width < 900 ? 24.0 : 48.0;
      final cols = width >= 1220 ? 4 : width >= 740 ? 3 : 2;
      final gap = width < 600 ? 11.0 : 20.0;
      final tileWidth = (width - 2 * padding - (cols - 1) * gap) / cols;
      return CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 30, padding, 27),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SneakerDesign.eyebrow('Your personal selection'),
            const SizedBox(height: 7),
            Text('The wishlist.',
              style: TextStyle(fontSize: width < 600 ? 32 : 42,
                fontWeight: FontWeight.w900, letterSpacing: -1.5)),
            const SizedBox(height: 5),
            Text('${saved.length} sneaker styles saved for later',
              style: Theme.of(context).textTheme.bodyMedium),
          ]),
        )),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(padding, 0, padding, 40),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, crossAxisSpacing: gap, mainAxisSpacing: gap,
              mainAxisExtent: (tileWidth * 1.05 + 126).clamp(255.0, 510.0)),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductTile(product: saved[index]),
              childCount: saved.length),
          ),
        ),
        const SliverToBoxAdapter(child: SneakerSiteFooter()),
      ]);
    });
  }
}
