part of '../shop_ui.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<ShopCubit>().state.stats;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Store dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Card(child: ListTile(leading: const Icon(Icons.receipt), title: const Text('Total orders'),
        trailing: Text('${stats['orders'] ?? 0}'))),
      Card(child: ListTile(leading: const Icon(Icons.payments_outlined), title: const Text('Delivered revenue'),
        trailing: Text(money((stats['revenue_cents'] ?? 0) as int)))),
      Card(child: ListTile(leading: const Icon(Icons.warning_amber), title: const Text('Low-stock size variants'),
        trailing: Text('${stats['low_stock_variants'] ?? 0}'))),
    ]);
  }
}
