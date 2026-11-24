import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

// Cart icon + live badge that shows how many products are selected.
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) => IconButton(
        tooltip: 'Open cart',
        onPressed: onPressed,
        icon: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Align(
                alignment: Alignment.center,
                child: Icon(Icons.shopping_cart_outlined, size: 27),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD73543),
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${cart.itemCount}',
                    key: const ValueKey('cart-badge-count'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
