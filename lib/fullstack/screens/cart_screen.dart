part of '../shop_ui.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final cart = cubit.state.cart;
    final count = cart.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = cart.fold<int>(0, (sum, item) {
      final p = cubit.product(item.productId);
      return sum + (p == null ? 0 : amount(p) * item.quantity);
    });
    if (cart.isEmpty) return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.shopping_bag_outlined, size: 65,
          color: SneakerDesign.orange),
        const SizedBox(height: 18),
        const Text('Your bag is empty.', style: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Your next favorite sneaker is waiting.'),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => cubit.selectTab(0),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Explore sneakers')),
      ]));

    Widget orderCard() => Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Order summary', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Subtotal ($count items)'),
              Text(money(subtotal), style: const TextStyle(
                fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Delivery'),
              Text('At checkout', style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
            const Divider(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(money(subtotal), style: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 23)),
            ]),
            const SizedBox(height: 20),
            SizedBox(height: 54, child: FilledButton.icon(
              onPressed: cubit.state.busy ? null : () => _checkout(context),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Continue to checkout'),
            )),
            const SizedBox(height: 13),
            const Text('Demo checkout only • No real payment is collected.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SneakerDesign.muted, fontSize: 11)),
          ],
        ),
      ),
    );

    Widget items() => ListView(
      padding: EdgeInsets.zero,
      children: [
        SneakerDesign.eyebrow('Your selection'),
        const SizedBox(height: 7),
        Text('Shopping bag.', style: Theme.of(context).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.3)),
        const SizedBox(height: 5),
        Text('$count items saved for checkout.',
          style: Theme.of(context).textTheme.bodyMedium),
        if (cubit.state.storeId != null) ...[
          const SizedBox(height: 13),
          Card(
            color: SneakerDesign.orange.withValues(alpha: .09),
            child: Padding(padding: const EdgeInsets.all(13),
              child: Row(children: [
                const Icon(Icons.storefront_outlined,
                  color: SneakerDesign.orange),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Store #${cubit.state.storeId} • Stock reserved only on successful checkout',
                  style: const TextStyle(fontSize: 12))),
              ])),
          ),
        ],
        const SizedBox(height: 16),
        for (final item in cart)
          if (cubit.product(item.productId) case final Json p)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: SizedBox(width: 99, height: 108,
                          child: ColoredBox(
                            color: SneakerDesign.imageSurface,
                            child: photo(p['image_url'] as String, height: 108))),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((p['brand'] as String).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10, letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              color: SneakerDesign.muted)),
                          const SizedBox(height: 4),
                          Text(p['name'] as String,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900,
                              fontSize: 15)),
                          const SizedBox(height: 5),
                          Text('EU ${item.size}  •  ${money(amount(p))}',
                            style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 9),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Remove one',
                              onPressed: () => cubit.changeQuantity(
                                item, item.quantity - 1),
                              icon: const Icon(Icons.remove_circle_outline, size: 21)),
                            Text('${item.quantity}', style: const TextStyle(
                              fontWeight: FontWeight.w900)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Add one',
                              onPressed: () => cubit.changeQuantity(
                                item, item.quantity + 1),
                              icon: const Icon(Icons.add_circle_outline, size: 21)),
                            const Spacer(),
                            Text(money(amount(p) * item.quantity),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12)),
                          ]),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );

    return LayoutBuilder(builder: (context, bounds) {
      final wide = bounds.maxWidth >= 860;
      return Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: EdgeInsets.all(wide ? 28 : 14),
          child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: items()),
                const SizedBox(width: 24),
                SizedBox(width: 330, child: SingleChildScrollView(
                  child: orderCard())),
              ])
            : Column(children: [
                Expanded(child: items()),
                SafeArea(top: false,
                  child: Padding(padding: const EdgeInsets.only(top: 9),
                    child: orderCard())),
              ]),
        ),
      ));
    });
  }

  Future<void> _checkout(BuildContext context) async {
    final cubit = context.read<ShopCubit>();
    final address = TextEditingController(text: 'Almaty, apartment / street');
    final promo = TextEditingController();
    var usePoints = false;
    var fulfillment = 'delivery';
    var district = 'Almaly';
    Future<Json>? quote;
    Future<Json> fetchQuote() => cubit.api.get(
      '/delivery/estimate?district=$district'
      '${cubit.state.storeId == null ? '' : '&store_id=${cubit.state.storeId}'}',
    ).then((value) => Map<String, dynamic>.from(value as Map));
    quote = fetchQuote();
    final order = await showDialog<(String, String, bool, String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Checkout • SneakerHub'),
          content: SizedBox(
            width: 470,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Demo checkout • No real payment is collected.'),
                  const SizedBox(height: 12),
                  if (cubit.state.storeId != null) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'delivery',
                          label: Text('Home delivery'), icon: Icon(Icons.local_shipping_outlined)),
                        ButtonSegment(value: 'pickup',
                          label: Text('Pickup'), icon: Icon(Icons.storefront_outlined)),
                      ],
                      selected: {fulfillment},
                      onSelectionChanged: (v) => refresh(() => fulfillment = v.first),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (fulfillment == 'delivery') ...[
                    DropdownButtonFormField<String>(
                      initialValue: district,
                      decoration: const InputDecoration(
                        labelText: 'Destination district • Almaty',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final area in const [
                          'Almaly','Auezov','Bostandyk','Medeu',
                          'Zhetysu','Turksib','Alatau','Nauryzbay',
                        ])
                          DropdownMenuItem(value: area, child: Text(area)),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        refresh(() {
                          district = value;
                          quote = fetchQuote();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<Json>(
                      future: quote,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Delivery estimate unavailable: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red));
                        }
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        final data = snapshot.data!;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estimated delivery: ${money(data['fee_cents'] as int)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${data['eta_min_days']}–${data['eta_max_days']} days • illustrative'),
                                const Text('No actual courier quote or live GPS.',
                                  style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ] else
                    const Text('Free pickup • Collect from selected demo branch.'),
                  TextField(
                    controller: address,
                    decoration: InputDecoration(
                      labelText: fulfillment == 'pickup'
                        ? 'Collection contact or note'
                        : 'Home address (street, building, apartment)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: promo, decoration: const InputDecoration(
                    labelText: 'Promo code (WELCOME10)', border: OutlineInputBorder())),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: usePoints,
                    title: const Text('Use loyalty points'),
                    onChanged: (v) => refresh(() => usePoints = v ?? false)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (address.text.trim().length < 8) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Enter a longer address or contact note')));
                  return;
                }
                Navigator.pop(dialogContext,
                    (address.text.trim(), promo.text.trim(), usePoints,
                     fulfillment, district));
              },
              child: const Text('Place demo order'),
            ),
          ],
        ),
      ),
    );
    address.dispose();
    promo.dispose();
    if (order != null && context.mounted) {
      await context.read<ShopCubit>().checkout(order.$1, order.$2, order.$3,
        fulfillment: order.$4,
        deliveryDistrict: order.$4 == 'delivery' ? order.$5 : null);
    }
  }
}
