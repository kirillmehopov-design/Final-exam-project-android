part of '../shop_ui.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final cart = cubit.state.cart;
    final total = cart.fold<int>(0, (v, item) {
      final product = cubit.product(item.productId);
      return v + (product == null ? 0 : amount(product) * item.quantity);
    });
    if (cart.isEmpty) return const Center(child: Text('Your cart is empty'));
    return Column(children: [
      if (cubit.state.storeId != null)
        Card(child: ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: Text('Store #${cubit.state.storeId} • branch stock'),
          subtitle: const Text('Pickup or delivery to your address'),
        )),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: cart.length,
        itemBuilder: (context, index) {
          final item = cart[index];
          final p = cubit.product(item.productId);
          if (p == null) return const SizedBox.shrink();
          return Card(child: ListTile(
            leading: SizedBox(width: 64, child: photo(p['image_url'] as String, height: 64)),
            title: Text(p['name'] as String),
            subtitle: Text('Size ${item.size} • ${money(amount(p))}'),
            trailing: SizedBox(width: 132, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => cubit.changeQuantity(item, item.quantity - 1)),
              Text('${item.quantity}'),
              IconButton(icon: const Icon(Icons.add_circle_outline),
                onPressed: () => cubit.changeQuantity(item, item.quantity + 1)),
            ])),
          ));
        },
      )),
      SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: Text('Subtotal ${money(total)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        FilledButton(onPressed: cubit.state.busy ? null : () => _checkout(context),
          child: const Text('Checkout')),
      ]))),
    ]);
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
