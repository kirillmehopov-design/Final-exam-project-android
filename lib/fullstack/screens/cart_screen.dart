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
    final address = TextEditingController(text: '123 Demo Street, Almaty');
    final promo = TextEditingController();
    var usePoints = false;
    final order = await showDialog<(String, String, bool)>(context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Confirm demo order'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('No real payment will be collected.'),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Delivery address')),
          TextField(controller: promo, decoration: const InputDecoration(labelText: 'Promo code (WELCOME10)')),
          CheckboxListTile(value: usePoints, title: const Text('Use loyalty points'),
            onChanged: (v) => setDialogState(() => usePoints = v ?? false)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, (address.text, promo.text, usePoints)),
            child: const Text('Place order')),
        ],
      )));
    if (order != null && context.mounted) {
      await context.read<ShopCubit>().checkout(order.$1, order.$2, order.$3);
    }
  }
}
