part of '../shop_ui.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ShopCubit>().state.products;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text('Warehouse / Supplies',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              onPressed: () => _history(context),
              icon: const Icon(Icons.history),
              label: const Text('Supply history'),
            ),
          ],
        ),
      ),
      for (final p in products) Card(child: Padding(padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            for (final e in Map<String, dynamic>.from(p['sizes'] as Map).entries)
              Chip(label: Text('${e.key}: ${e.value}')),
          ]),
          Text('Discount: ${p['discount']}%'),
          Wrap(spacing: 8, children: [
            OutlinedButton.icon(icon: const Icon(Icons.add_box_outlined),
              label: const Text('Warehouse restock'), onPressed: () => _supply(context, p)),
            OutlinedButton.icon(icon: const Icon(Icons.store_outlined),
              label: const Text('Restock a branch'), onPressed: () => _branchSupply(context, p)),
            OutlinedButton.icon(icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Set discount'), onPressed: () => _discount(context, p)),
          ]),
        ]))),
    ]);
  }

  Future<void> _history(BuildContext context) async {
    try {
      final data = await context.read<ShopCubit>().api.get('/admin/supplies');
      final records = asJsonList(data);
      if (!context.mounted) return;
      await showDialog<void>(context: context, builder: (dialog) => AlertDialog(
        title: const Text('Received shipments'),
        content: SizedBox(
          width: 480, height: 370,
          child: records.isEmpty
              ? const Center(child: Text('No stock deliveries recorded yet'))
              : ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final entry = records[i];
                    final product = context.read<ShopCubit>()
                        .product(entry['product_id'] as int);
                    return ListTile(
                      leading: const Icon(Icons.inventory_outlined),
                      title: Text(product?['name'] as String? ??
                          'Product #${entry['product_id']}'),
                      subtitle: Text('EU ${entry['size']} • ${entry['created_at']}',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Text('+${entry['quantity']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog),
            child: const Text('Close')),
        ],
      ));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load shipments: $error')),
      );
    }
  }

  Future<void> _branchSupply(BuildContext context, Json product) async {
    final api = context.read<ShopCubit>().api;
    List<Json> branches;
    try {
      branches = asJsonList(await api.get('/stores'));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
      return;
    }
    if (!context.mounted || branches.isEmpty) return;
    int branchId = branches.first['id'] as int;
    int size = 42;
    final field = TextEditingController(text: '5');
    final result = await showDialog<(int,int,int)>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, change) => AlertDialog(
          title: Text('Restock ${product['name']}'),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: branchId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Branch'),
                items: [
                  for (final branch in branches)
                    DropdownMenuItem(value: branch['id'] as int,
                      child: Text(branch['name'] as String)),
                ],
                onChanged: (v) => change(() => branchId = v ?? branchId),
              ),
              DropdownButtonFormField<int>(
                initialValue: size,
                decoration: const InputDecoration(labelText: 'EU size'),
                items: [for (var n = 39; n <= 45; n++)
                  DropdownMenuItem(value: n, child: Text('EU $n'))],
                onChanged: (v) => change(() => size = v ?? size),
              ),
              TextField(controller: field, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity to receive')),
              const SizedBox(height: 8),
              const Text('Restocking a sold-out size sends in-app alerts to subscribers.',
                style: TextStyle(fontSize: 12)),
            ],
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final quantity = int.tryParse(field.text);
              if (quantity == null || quantity <= 0) return;
              Navigator.pop(dialog, (branchId, size, quantity));
            }, child: const Text('Receive at branch')),
          ],
        ),
      ),
    );
    field.dispose();
    if (result != null && context.mounted) {
      await context.read<ShopCubit>().restockBranch(
          result.$1, product['id'] as int, result.$2, result.$3);
    }
  }

  Future<void> _supply(BuildContext context, Json product) async {
    final stock = Map<String, dynamic>.from(product['sizes'] as Map);
    var size = int.parse(stock.keys.first);
    final quantity = TextEditingController(text: '5');
    final result = await showDialog<(int, int)>(context: context,
      builder: (dialog) => StatefulBuilder(builder: (dialog, setDialog) => AlertDialog(
        title: const Text('Receive stock'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(initialValue: size,
            items: [for (final s in stock.keys) DropdownMenuItem(value: int.parse(s), child: Text('EU $s'))],
            onChanged: (v) => setDialog(() => size = v ?? size)),
          TextField(controller: quantity, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialog, (size, int.tryParse(quantity.text) ?? 0)),
            child: const Text('Add supply')),
        ],
      )));
    if (result != null && context.mounted) {
      await context.read<ShopCubit>().restock(product['id'] as int, result.$1, result.$2);
    }
  }

  Future<void> _discount(BuildContext context, Json p) async {
    final field = TextEditingController(text: '${p['discount']}');
    final percent = await showDialog<int>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Discount (%)'),
      content: TextField(controller: field, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '0 to 90')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialog, int.tryParse(field.text)),
          child: const Text('Save')),
      ],
    ));
    if (percent != null && context.mounted) {
      await context.read<ShopCubit>().changeDiscount(p['id'] as int, percent);
    }
  }
}
