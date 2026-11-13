# SneakerHub Full-Stack Capstone — Milestone 2 Prototype

This branch builds on the Flutter Milestone 1 project without deleting the old `lib/screens`, `lib/models`, `lib/widgets` and `lib/data` files. New entry point: `lib/main.dart`, new UI: `lib/fullstack/`, new REST backend: `backend/`.

## Implemented in the demo

- Flutter store: search, brand filtering, sneakers, sizes, favorites and cart
- Three real sign-in roles: customer, admin and courier
- SQLite inventory per sneaker / shoe size, receiving stock, automatic reservations at checkout
- Orders and delivery lifecycle: placed → preparing → out_for_delivery → arrived → delivered
- 6-digit delivery code visible **only** to the owning customer, after courier marks arrival; expires in 20 minutes; limited attempts
- Promo code `WELCOME10`, discount management, notifications for favorites on price drops
- Verified-purchase product reviews, loyalty points awarded after delivery
- Admin dashboard with orders, delivered revenue and low-stock count
- REST client (`http`) + Cubit state management (`flutter_bloc`, a BLoC-family API)
- API `/docs` interactive Swagger documentation
- Python endpoint tests for user permissions, buying, discount, stock and delivery


## FINAL.docx rubric updates (feature/final-rubric-100)

This branch addresses the instructor's FINAL assessment without modifying the original Milestone 1 on `main`.

- Persistent dark/light theme initialized from `shared_preferences` before `runApp`
- Cached cart lines and favorite IDs in JSON on disk; restored on app startup
- BLoC/Cubit remains the single source of UI state; live cart/favorites badges
- Typed `ApiProduct.fromJson` includes safe `(json['price'] as num).toDouble()`
- Async REST catalog loading, network errors with Retry, and pull-to-refresh
- Debounced search (350 ms), a potential rubric bonus
- New Flutter tests for type-safe parsing and cached state restoration
- GitHub Actions checks Flutter analysis and Flutter tests

Refer to [FINAL checklist](docs/FINAL_CHECKLIST.md) and [cloud API instructions](docs/CLOUD_API_SETUP.md).

**Important:** The FastAPI server is local by default. A deployed public HTTPS URL is required for the cloud REST criterion; this repository does not deploy that service automatically. Native Android/iOS testing and the 3-minute defense remain your responsibility.

### Quick verification

```bash
flutter create --project-name sneakerhub .
flutter pub get
flutter analyze --no-fatal-infos lib/main.dart lib/fullstack lib/providers lib/models/api_product.dart lib/models/cart_line.dart test
flutter test test/api_product_test.dart test/local_store_test.dart
```

After adding items to the cart and switching to dark theme, fully stop the application and restart it. Theme and cached cart should be restored. Sign in to access the backend data again.

## Run the server (Terminal 1)

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux: source .venv/bin/activate
pip install -r requirements.txt
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

Use `http://127.0.0.1:8000/docs` for Swagger UI and `http://127.0.0.1:8000/health` to test connectivity. A local `backend/sneakerhub.sqlite3` database is created automatically and excluded from Git.

## Run Flutter (Terminal 2)

Requires Flutter with Dart >= 3.4.0. If the project does not yet include generated native/web scaffolding, run `flutter create .` once from the repository root.

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

For Android emulator, use `--dart-define=API_BASE_URL=http://10.0.2.2:8000`; on a real phone, use `http://<your-computer-LAN-IP>:8000` and connect both devices to the same network. Allow development HTTP traffic in Android manifest / network-security configuration as needed. Production must use HTTPS.

## Demo accounts

| Role | Email | Password |
| --- | --- | --- |
| Customer | `customer@demo.test` | `DemoPass123!` |
| Admin | `admin@demo.test` | `DemoPass123!` |
| Courier | `courier@demo.test` | `DemoPass123!` |

These credentials are **for local demonstration only**. Real signup can register a customer, never an admin or courier.

## Demo walk-through

1. Sign in as customer, open a sneaker, select a size, add it to the cart and enter an address. Optionally use `WELCOME10`.
2. Sign out, log in as admin, open Orders and press **Start preparing**, then **Assign courier & dispatch**.
3. Sign out, log in as courier, open Deliveries and select **I have arrived (demo)**.
4. Sign out, return to customer, open Orders, press **Show delivery code** and copy six digits.
5. Log in as courier again, enter code to finish delivery.
6. Return as customer to view points, notifications and write a verified-purchase review.
7. As admin, receive stock or update a discount; customers who favorited the product receive an in-app price-drop notification when they refresh.

## Tests

From the project root:

```bash
pip install -r backend/requirements.txt
python -m pytest backend/tests -q
```

Backend tests have been executed locally (3 passed). Flutter has **not** been compiled or run in the preparation environment; run `flutter analyze`, `flutter test` and a device demo yourself before presenting.

## Technical notes and limitations

- This is an **educational prototype**, not a production commerce service. Checkout records an order but takes **no payment**.
- Courier arrival is a simulated manual event. GPS proximity, live tracking/maps, background push (FCM/APNs), email/SMS delivery and address verification are **not integrated**.
- Notifications are stored in SQLite and shown **inside the app** when refreshed; they do not appear as OS push alerts.
- The delivery code is derived with server-side HMAC and the courier cannot request it. Configure `SNEAKERHUB_OTP_SECRET` securely on the server; rotate/reissue codes during production migrations.
- Demo sessions are in-memory on the Flutter client and hashed in SQLite on the server. App restart requires login. For production add persistent secure-token storage, session expiry, API rate limiting, email verification, audit trails, HTTPS and strict CORS rules.
- Product photos come from third-party public image URLs, and may not load without an internet connection. Replace them with licensed assets for distribution.
- Customer points and demo coupon are simplified; full order cancellations, refunds, payment webhooks, background jobs and supply supplier accounting are beyond this prototype.

## Source tree

```text
backend/
  app.py                  SQLite persistence + REST endpoints
  requirements.txt
  tests/test_app.py       Core integration tests
lib/
  main.dart               New BLoC app entry point
  fullstack/
    api_client.dart       Typed HTTP wrapper
    shop_cubit.dart       Cubit state and backend interaction
    shop_ui.dart          Responsive customer/admin/courier screens
  screens/, models/, ...  Legacy Milestone 1 files, preserved
```
