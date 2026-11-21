part of '../shop_ui.dart';

/// Branch transfer workflow. No GPS tracking or automatic trucks:
/// customers request, admins approve and confirm arrival.
class TransferRequestsPage extends StatefulWidget {
  const TransferRequestsPage({super.key});

  @override
  State<TransferRequestsPage> createState() => _TransferRequestsPageState();
}

class _TransferRequestsPageState extends State<TransferRequestsPage> {
  late Future<List<Json>> _requests;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _requests = context.read<ShopCubit>().transferRequests();
  }

  Future<void> _decide(Json transfer, String status) async {
    await context.read<ShopCubit>()
        .adminTransferDecision(transfer['id'] as int, status);
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        context.watch<ShopCubit>().state.user?['role'] == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Manage store transfers' : 'My store transfers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh transfers',
            onPressed: () => setState(_reload),
          ),
        ],
      ),
      body: FutureBuilder<List<Json>>(
        future: _requests,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to load transfers'),
                Text('${snapshot.error}', textAlign: TextAlign.center),
                FilledButton(onPressed: () => setState(_reload),
                  child: const Text('Retry')),
              ],
            ));
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!;
          if (requests.isEmpty) return const Center(
            child: Text('No transfer requests yet'));
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _requests;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final transfer = requests[index];
                final status = transfer['status'] as String;
                final requested = status == 'requested';
                final approved = status == 'approved';
                return Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(
                          '${transfer['product_name']} • EU ${transfer['size']}',
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold))),
                        Chip(label: Text(status.replaceAll('_',' '))),
                      ]),
                      Text('From: ${transfer['source_name']}'),
                      Text('To: ${transfer['destination_name']}'),
                      Text('${transfer['quantity']} pair(s) • Demo transfer #${transfer['id']}'),
                      const SizedBox(height: 8),
                      if (requested)
                        const Text('Waiting for store staff approval. No stock reserved yet.'),
                      if (approved)
                        const Text('Pair reserved at source. Staff must confirm arrival.'),
                      if (status == 'completed')
                        const Text('Arrived: available to purchase at destination.'),
                      if (isAdmin && (requested || approved))
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          if (requested) ...[
                            FilledButton(
                              onPressed: () => _decide(transfer, 'approved'),
                              child: const Text('Approve and reserve')),
                            OutlinedButton(
                              onPressed: () => _decide(transfer, 'rejected'),
                              child: const Text('Reject')),
                          ],
                          if (approved) ...[
                            FilledButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => _decide(transfer, 'completed'),
                              label: const Text('Confirm arrival')),
                            OutlinedButton(
                              onPressed: () => _decide(transfer, 'cancelled'),
                              child: const Text('Cancel • return stock')),
                          ],
                        ]),
                    ],
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}
