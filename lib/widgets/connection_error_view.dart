import 'package:flutter/material.dart';

class ConnectionErrorView extends StatelessWidget {
  const ConnectionErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.blueGrey),
        const SizedBox(height: 20),
        const Text('Connection problem',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.blueGrey, height: 1.4)),
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry Connection'),
        ),
      ]),
    ));
  }
}
