part of '../shop_ui.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ShopCubit>().state.products;
    return ListView(padding: const EdgeInsets.all(12), children: [
      const Padding(padding: EdgeInsets.all(8), child: Text('Warehouse / Supplies',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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
              label: const Text('Receive supply'), onPressed: () => _supply(context, p)),
            OutlinedButton.icon(icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Set discount'), onPressed: () => _discount(context, p)),
          ]),
        ]))),
    ]);
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
