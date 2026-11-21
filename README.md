# SneakerHub Almaty — Final Exam (based on Lab 11)

Flutter mobile/web storefront + FastAPI REST + SQLite, developed from the user's **Lab 11** source. The old Lab 11 catalog, model, Provider cart, notes, tests, and UI modules remain in the repository; the main entry point now opens the enhanced BLoC storefront.

This is a **demonstration prototype**, not an actual retailer. **All 10 Almaty branches are fictional, placed at approximate map coordinates, with illustrative opening hours.** Do not send customers to these points expecting a SneakerHub business.

## What's in this version

| Feature | Implementation |
|---|---|
| Sneaker catalog | 12 demo sneaker models with images, sizes, stock, discounts and prices in KZT (₸) |
| Search and discovery | Debounced name/brand search, brand/category filters, in-stock and sale filters, price/discount sorting |
| Store locator | OpenStreetMap interactive map, 10 demo markers across all 8 Almaty districts, district dropdown, store cards and Google Maps directions link |
| User accounts | REST signup/login, customer/admin/courier demo roles |
| Cart and saved items | Shared `ShopCubit` state; quantities and cart persisted in `SharedPreferences`, favorites synced via REST |
| Orders | Simulated checkout with address and WELCOME10 coupon, admin status/assignment, courier handoff |
| Delivery code | Six-digit code shown to customer only after courier presses **I have arrived (demo)**; server verifies it and expires after 20 minutes |
| Discount notifications | Stored in SQLite; in-app alerts for favorited products on price reductions, refreshed while the app is open |
| Inventory | Admin size-level stock/supply changes, low-stock statistics, discounts |
| Persistence | Persistent theme, cart, favorites, and the original Lab 11 offline notes / username |
| Architecture | Flutter BLoC/Cubit + REST API + SQLite, with separated folders and role-based UI |
| Tests | Flutter tests and Python FastAPI end-to-end tests, GitHub Actions workflows |

**Important limitations:** No real payment processing, SMS, background push notifications, GPS courier proximity, verified store addresses/hours, per-branch inventory or live delivery routes. Courier arrival is manual; customer notifications are **in-app**, not mobile OS pushes. Photos are illustrative public third-party images, not exact product SKU listings. The demo server uses permissive CORS and simple local demo auth, **not** production security settings.

## Open the COMPLETE app in Chrome (Windows)

Get this branch, open the folder containing `pubspec.yaml` in Android Studio or PowerShell.

**Terminal 1 — start REST API and database:**

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app:app --reload --host 127.0.0.1 --port 8000
```

If script execution is blocked by PowerShell, skip activation and invoke `.venv\Scripts\python.exe -m pip install -r requirements.txt` followed by `.venv\Scripts\python.exe -m uvicorn app:app --reload --host 127.0.0.1 --port 8000`.

After starting, check http://127.0.0.1:8000/health and browse the API at http://127.0.0.1:8000/docs. The backend creates `backend/sneakerhub.sqlite3` automatically. This data file remains on your computer and is excluded from Git.

**Terminal 2 — launch Flutter Web:**

```powershell
flutter create --platforms=android,web .
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Both terminals must remain running. **Running Flutter without the FastAPI server will show network errors instead of product data.** For physical Android use your computer's LAN IP; for Android emulator use `http://10.0.2.2:8000`. Production hosting must be HTTPS with restricted CORS and appropriate authentication.

## Login accounts

| Role | Email | Password |
|---|---|---|
| Customer | `customer@demo.test` | `DemoPass123!` |
| Admin | `admin@demo.test` | `DemoPass123!` |
| Courier | `courier@demo.test` | `DemoPass123!` |

You can also register a new customer account.

## Try the complete demo

1. Sign in as **customer**. Search for shoes, filter models by brand, price, category, discount and size availability.
2. Open **Stores**, filter by district, tap any of the 10 fictional Almaty markers and open directions.
3. Save a sneaker, choose EU size, add to cart and submit a **demo** order using a sample Almaty delivery address.
4. Sign in as **admin** and move the order to `preparing`, assign the demo courier, dispatch, restock sizes or set a discount.
5. Sign in as **courier** and use **I have arrived (demo)**.
6. Sign in as the original **customer** to see the delivery code in Orders; sign in as **courier** to enter the code and finish delivery.
7. Check **Profile** for in-app notifications and **Offline notes and settings (Lab 11)** for username, local notes and dark theme.

On-screen alerts update by polling while the user is signed in (roughly every 25 seconds); they are **not** actual push messages delivered while the app is closed.

## Automated tests

```powershell
flutter test
python -m pytest backend/tests -q
```

GitHub Actions also runs Flutter analyze/tests/web build and Python tests on the feature branch. See `.github/workflows/final-lab11-checks.yml`.

## Grading status / not yet implemented

- Present: multiple connected screens, BLoC global state, HTTP, safe JSON parsing, retry/loading/error, Hero, PageView, persistent local state, backend/database, map, catalog, discount and warehouse functions.
- Verify on your machines: browser and mobile layout, device cold-quit/restart, source-based viva, actual cloud API deployment (the default API endpoint is LOCAL).
- Bonus: no production deep-link routing, encrypted KeyStore/Keychain session, custom branded splash/app icon or background push integration yet.
- The 3-minute live demonstration on an **Android phone/emulator** is still required by the instructor's rubric; Chrome is useful for development but may not satisfy that presentation criterion.

## Source layout

```text
lib/main.dart                         app entry, Provider + BLoC setup
lib/fullstack/screens/                catalog, stores, product, cart, orders, admin, profile
lib/fullstack/widgets/                product cards / images
lib/fullstack/shop_cubit.dart         state + commerce actions
lib/fullstack/api_client.dart         HTTP client
lib/providers/notes_vault_provider.dart  original Lab 11 offline persistence
lib/screens/notes_vault_screen.dart   original Lab 11 notes & settings
backend/app.py                        FastAPI routes / SQLite tables
backend/tests/test_app.py             API flow/permissions/store tests
```

## Deployment notes

Do not expose demo passwords publicly on a live deployment. Use a hosted database, backups, HTTPS, secrets management, properly scoped CORS, rate-limiting, persistent secure sessions and real push/GPS services before production. Hosting the API is a separate setup step and is not claimed completed.
