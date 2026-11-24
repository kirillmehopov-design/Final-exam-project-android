part of '../shop_ui.dart';

/// Functional site footer, shared across catalogue, showroom and orders.
/// The copyright bar is visible and independent of any external website.
class SneakerSiteFooter extends StatelessWidget {
  const SneakerSiteFooter({super.key, this.onBackToTop, this.compact = false});
  final VoidCallback? onBackToTop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShopCubit>();
    final width = MediaQuery.sizeOf(context).width;
    final small = width < 670;
    final role = context.watch<ShopCubit>().state.user?['role'] as String? ?? 'customer';
    final isCustomer = role == 'customer';
    if (compact) {
      return Container(
        width: double.infinity,
        color: SneakerDesign.graphite,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        child: const Text('© SneakerHub 2026  ·  MADE FOR ALMATY  ·  DEMO STORE',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 10,
            fontWeight: FontWeight.w600, letterSpacing: 1.1)),
      );
    }
    Widget link(String label, int tab) => TextButton(
      onPressed: () => cubit.selectTab(tab),
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
    return Container(
      width: double.infinity,
      color: SneakerDesign.graphite,
      child: Column(children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.fromLTRB(small ? 24 : 48, 38,
              small ? 24 : 48, 34),
            child: Wrap(
              spacing: 44,
              runSpacing: 26,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                SizedBox(width: small ? width - 50 : 380,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('SNEAKERHUB',
                        style: TextStyle(color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.w900, letterSpacing: -1.4)),
                      Text('™', style: TextStyle(color: SneakerDesign.lime,
                        fontSize: 15, fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 12),
                    const Text('Good sneakers. Better moves.\nDiscover your next pair in Almaty.',
                      style: TextStyle(color: Colors.white70,
                        height: 1.55, fontSize: 14)),
                    const SizedBox(height: 13),
                    const Text('Educational prototype. Store locations and delivery estimates are simulated.',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('EXPLORE', style: TextStyle(color: SneakerDesign.lime,
                    fontWeight: FontWeight.w900, letterSpacing: 1.8, fontSize: 11)),
                  const SizedBox(height: 9),
                  if (isCustomer) ...[
                    link('Shop sneakers', 0),
                    link('Almaty stores', 2),
                    link('My wishlist', 1),
                  ] else ...[
                    link('Dashboard', 0),
                    link('Orders', 1),
                  ],
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('YOUR SNEAKERHUB', style: TextStyle(color: SneakerDesign.lime,
                    fontWeight: FontWeight.w900, letterSpacing: 1.8, fontSize: 11)),
                  const SizedBox(height: 9),
                  if (isCustomer) ...[
                    link('Shopping bag', 3),
                    link('Track orders', 4),
                    link('Account & alerts', 5),
                  ] else
                    link('My profile', role == 'courier' ? 1 : 3),
                ]),
                if (onBackToTop != null)
                  OutlinedButton.icon(
                    onPressed: onBackToTop,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SneakerDesign.lime,
                      side: const BorderSide(color: SneakerDesign.lime)),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 17),
                    label: const Text('Back to top'),
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: 1, color: Colors.white24,
          width: double.infinity,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Wrap(
            spacing: 20, runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: const [
              Text('© SneakerHub 2026. All rights reserved.',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text('DESIGNED FOR THE CULTURE  /  ALMATY, KZ',
                style: TextStyle(color: Colors.white54,
                  letterSpacing: 1.2, fontSize: 10)),
            ],
          ),
        ),
      ]),
    );
  }
}
