# SneakerHub FINAL — 3-minute live defense (simple English)

Use the real running app, not screenshots. The cloud API rubric requires a live publicly hosted HTTPS API, not localhost.

## 0:00–0:50 — Pitch (first person)

"Hello. My project is SneakerHub, a mobile sneaker store created with Flutter. People can discover shoes, choose a size, save favorites and add items to their cart. The project also has customer, courier and admin roles. I built this app to bring product discovery, inventory and the order-delivery process into one place."

## 0:50–2:20 — Live app demo

1. Open the Feed / Shop. Show products arriving from the REST API, search by name, and filter by brand.
2. Pull down to refresh. Mention Loading, Success and Error + Retry. Use a controlled disconnected backend or invalid URL to demonstrate failure, then restore the API.
3. Open a product detail (Navigator), select a size, add it to cart. Show the cart badge updating automatically.
4. Save a product as a favorite and switch to Favorites. Show the saved badge updating.
5. Open Profile, switch to Dark Theme.
6. Close and reopen the app. Show the same theme and cached cart.
7. If time allows, switch demo roles to show admin stock and courier delivery confirmation.

## 2:20–3:00 — Code explanation

"I use flutter_bloc and Cubit for global app state. When cart or favorites change, ShopCubit emits a new ShopState. Screens using context.watch rebuild automatically; buttons use context.read to call functions. ApiClient sends async HTTP requests and handles server errors. ApiProduct.fromJson safely converts price from num to double. LocalStore saves the cart, favorites and theme with shared_preferences. main.dart loads the theme and cached data before runApp."

## Instructor questions — answer by opening code

### Q1: How does Global State Management work between screens?

Open:
- lib/fullstack/shop_cubit.dart
- lib/fullstack/screens/app_shell.dart
- lib/fullstack/widgets/product_tile.dart

Answer: "ShopCubit stores the cart and favorites once. A button calls a Cubit method using context.read. That method emits a new ShopState. Other screens access state with context.watch and redraw automatically. The navigation badge uses state.cart and state.favorites."

### Q2: What happens if the REST API fails?

Open:
- lib/fullstack/api_client.dart
- lib/fullstack/shop_cubit.dart
- lib/fullstack/screens/catalog_screen.dart

Answer: "The API client makes HTTP calls and checks response status. If a request fails, the state keeps an error message. The UI shows a Retry button. A successful retry loads the products again. A loading indicator appears while a request is in progress."

### Q3: How do you save data after closing the app?

Open:
- lib/main.dart
- lib/providers/local_store.dart
- lib/providers/theme_cubit.dart

Answer: "shared_preferences stores serialized JSON for the cart and favorites, plus a boolean for Dark Theme. The app reads this data before runApp and the Cubits start with the saved values. It does not store user passwords in this cache."

### Q4: Why is Product.fromJson important?

Open:
- lib/models/api_product.dart

Answer: "The API returns JSON. My Product.fromJson constructor creates a typed model from it. The price is converted with (json['price'] as num).toDouble(), so both integer and decimal JSON prices work."

## Never claim without a real demo

- If there is no deployed public server, do not claim the cloud REST API point.
- If you have not force-quit and restarted a phone/emulator build, do not claim that test was completed.
- Real payments, GPS auto-arrival and OS-level push notifications are not implemented.
