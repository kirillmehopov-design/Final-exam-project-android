part of '../shop_ui.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ShopCubit>();
    final role = cubit.state.user?['role'] as String? ?? 'customer';
    final orders = cubit.state.orders;
    if (orders.isEmpty) return const Center(child: Text('No orders yet'));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final id = order['id'] as int;
        final status = order['status'] as String;
        final items = asJsonList(order['items']);
        return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Order #$id', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Chip(label: Text(status.replaceAll('_', ' '))),
            ]),
            if (order['store_name'] != null)
              Text('${order['store_name']} • ${order['fulfillment'] == 'pickup' ? 'Collect from store' : 'Home delivery'}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${order['address']}'),
            const SizedBox(height: 6),
            for (final item in items) Text('${item['name']} • EU ${item['size']} × ${item['quantity']}'),
            const SizedBox(height: 8),
            if ((order['fulfillment'] as String?) == 'delivery' &&
                order['delivery_district'] != null) ...[
              Text('Delivery to ${order['delivery_district']} • ${money(order['delivery_fee_cents'] as int)}',
                style: Theme.of(context).textTheme.bodySmall),
              Text('Estimated ${order['eta_min_days']}–${order['eta_max_days']} days (demo)',
                style: Theme.of(context).textTheme.bodySmall),
            ],
            if ((order['fulfillment'] as String?) == 'pickup')
              const Text('Pickup is free • Collection code appears when ready.'),
            Text('Order total: ${money(order['total_cents'] as int)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (role == 'customer' && (status == 'arrived' || status == 'ready_for_pickup'))
              FilledButton.icon(icon: const Icon(Icons.pin), label: const Text('Show delivery code'),
                onPressed: () => _showCode(context, id)),
            if (role == 'admin' && status == 'placed')
              FilledButton(onPressed: () => cubit.adminStatus(id, 'preparing'),
                child: const Text('Start preparing')),
            if (role == 'admin' && status == 'preparing' &&
                order['fulfillment'] == 'pickup')
              FilledButton(onPressed: () => cubit.adminStatus(id, 'ready_for_pickup'),
                child: const Text('Mark ready for collection')),
            if (role == 'admin' && status == 'ready_for_pickup')
              FilledButton(onPressed: () => _verifyPickup(context, id),
                child: const Text('Verify customer pickup code')),
            if (role == 'admin' && status == 'preparing' &&
                order['fulfillment'] != 'pickup')
              FilledButton(onPressed: cubit.state.couriers.isEmpty ? null : () =>
                cubit.adminStatus(id, 'out_for_delivery',
                  courierId: cubit.state.couriers.first['id'] as int),
                child: const Text('Assign courier & dispatch')),
            if (role == 'courier' && status == 'out_for_delivery')
              FilledButton(onPressed: () => cubit.courierArrive(id),
                child: const Text('I have arrived (demo)')),
            if (role == 'courier' && status == 'arrived')
              FilledButton(onPressed: () => _verifyCode(context, id),
                child: const Text('Enter customer code')),
          ],
        )));
      });
  }

  Future<void> _showCode(BuildContext context, int id) async {
    try {
      final code = await context.read<ShopCubit>().customerCode(id);
      if (!context.mounted) return;
      await showDialog<void>(context: context, builder: (dialog) => AlertDialog(
        title: const Text('Handoff code (pickup: 3 days, delivery: 20 min)'),
        content: SelectableText(code, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, letterSpacing: 6, fontWeight: FontWeight.bold)),
        actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Close'))],
      ));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _verifyPickup(BuildContext context, int id) async {
    final field = TextEditingController();
    final code = await showDialog<String>(
      context: context, builder: (dialog) => AlertDialog(
        title: const Text('Pickup code'),
        content: TextField(controller: field,
          keyboardType: TextInputType.number, maxLength: 6,
          decoration: const InputDecoration(labelText: '6-digit customer code')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, field.text),
            child: const Text('Confirm pickup')),
        ],
      ),
    );
    field.dispose();
    if (code != null && context.mounted) {
      await context.read<ShopCubit>().confirmPickup(id, code);
    }
  }

  Future<void> _verifyCode(BuildContext context, int id) async {
    final field = TextEditingController();
    final code = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('One-time handoff code'),
      content: TextField(controller: field, keyboardType: TextInputType.number,
        maxLength: 6, decoration: const InputDecoration(labelText: '6 digits from customer')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialog, field.text), child: const Text('Verify')),
      ],
    ));
    if (code != null && context.mounted) await context.read<ShopCubit>().courierDeliver(id, code);
  }
}
