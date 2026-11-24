# SneakerHub V2 — Almaty Concept Store

An original, fully redesigned Flutter / FastAPI / SQLite sneaker-shop prototype
based on the student's Lab 11. **© SneakerHub 2026** is displayed in its footer.

- Editorial homepage, categories, product cards, carousel, responsive navigation
- 10 fictional SneakerHub branches across Almaty with per-size stock
- Cart, pickup, district-based demo delivery, requests, notifications and admin
- Shared BLoC state, JSON persistence and encrypted native session storage

**Important:** Default REST API is LOCAL, not verified CLOUD deployed.
For honest grading status see [FINAL(2) rubric audit](docs/FINAL2_RUBRIC_AUDIT.md).
For UI and device tests see [V2 UX notes](docs/UI_V2_DEFENSE.md).

Custom icon/splash assets are generated in CI using `tooling/create_brand_icon.py` and the Flutter launcher/splash packages. The Actions artifact includes them; the raw source ZIP requires the generation commands described in the UX notes.

---

# SneakerHub Almaty — Final Exam (based on Lab 11)

Flutter mobile/web storefront + FastAPI REST + SQLite, developed from the user's **Lab 11** source. The old Lab 11 catalog, model, Provider cart, notes, tests, and UI modules remain in the repository; the main entry point now opens the enhanced BLoC storefront.

This is a **demonstration prototype**, not an actual retailer. **All 10 Almaty branches are fictional, placed at approximate map coordinates, with illustrative opening hours.** Do not send customers to these points expecting a SneakerHub business.

## What's in this version

| Feature | Implementation |
|---|---|
| Sneaker catalog | 12 demo sneaker models with images, sizes, **per-branch** stock (including sold-out sizes), discounts and prices in KZT (₸) |
| Search and discovery | Debounced name/brand search, brand/category filters, in-stock and sale filters, price/discount sorting |
| Store locator | OpenStreetMap interactive map, 10 demo markers across all 8 Almaty districts, district dropdown, unique named boutique profiles, storefront interior image carousel, and Google Maps directions link |
| User accounts | REST signup/login, customer/admin/courier demo roles |
| Cart and saved items | Shared `ShopCubit` state; quantities and cart persisted in `SharedPreferences`, favorites synced via REST |
| Orders | Simulated checkout, home delivery or branch pickup, WELCOME10 coupon, admin status/assignment, courier handoff |
| Delivery code | Six-digit code shown after courier arrival (20 minutes) or pickup readiness (3 days); courier or admin verifies it |
| Discount notifications | Stored in SQLite; in-app alerts for favorited products on price reductions, refreshed while the app is open |
| Back-in-stock alerts | Subscriber chooses a **sold-out size at a specific branch**; the database remembers the subscription and creates an in-app notification after that branch is restocked |
| Compare branches | On the sneaker detail page, select an EU size then tap **Check this size at other stores** to see which branches have it |
| Store profiles | Named boutique, fictional description/hours, photo carousel, model list and per-size quantity |
| Branch supplies | Admin picks product + branch + EU size + quantity; stock is changed only for that branch |
| Inventory | Admin size-level stock/supply changes, low-stock statistics, discounts |
| Persistence | Persistent theme, cart, favorites, and the original Lab 11 offline notes / username |
| Architecture | Flutter BLoC/Cubit + REST API + SQLite, with separated folders and role-based UI |
| Tests | Flutter tests and Python FastAPI end-to-end tests, GitHub Actions workflows |

**Important limitations:** No real payment processing, SMS, background push notifications, GPS courier proximity, verified store addresses/hours, per-branch inventory or live delivery routes. Courier arrival is manual; customer notifications are **in-app**, not mobile OS pushes. Photos are illustrative public third-party images, not exact product SKU listings. The demo server uses permissive CORS and simple local demo auth, **not** production security settings.

## Frontend redesign — Nike / END.-inspired, original SneakerHub styling

The Flutter web/mobile experience uses an original retail visual system, rather
than copying another shop's code or branding:

- Editorial high-contrast welcome screen, product hero and orange call-to-action
- Consistent off-white / ink / vivid orange palette, rounded controls, typography
- Desktop tab navigation and compact mobile navigation with cart badge
- Debounced search, brand/category chips, pricing/sale filters and responsive grid
- Shared product-card component in main catalogue, favorites and branch catalogues
- Two-column product detail on desktop; stacked swipe gallery and EU-size picker on mobile
- Larger map store cards and a responsive bag/order-summary checkout
- All former REST/BLoC/SQLite functionality remains in place

The product and editorial images are illustrative third-party URLs that require
an Internet connection. They are not actual SKU-specific licensed product photos,
so replace with owned/licensed assets before a real retail release.

Manual layout checks worth doing for the in-class defense: Chrome desktop around
1440px wide, responsive 768px tablet, 390px and 320px mobile viewport sizes,
both light and dark modes, sign-in, gallery swipe, cart quantity, and map store
selection. CI verifies Dart analysis, tests and web compilation; it does not
replace a real visual UX review in the browser.

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

After starting, check http://127.0.0.1:8000/health and browse the API at http://127.0.0.1:8000/docs. The backend creates `backend/sneakerhub.sqlite3` automatically. Existing local databases are migrated with per-branch stock tables and extra fulfillment fields. Branch coordinates, store descriptions, model stock and photos are fictional demo data. This data file remains on your computer and is excluded from Git.

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
3. Open one location's profile, swipe through photos, explore its catalogue. Choose a product and size. If it is sold out, subscribe for restock and use **Check this size at other stores**. Add an available pair from a specific branch to the cart, then choose **home delivery** or **pickup from this branch** at checkout.
4. Sign in as **admin** and move a delivery order to `preparing`, assign the demo courier and dispatch, OR mark a pickup order `ready_for_pickup`. Restock a specific store's sold-out size to trigger subscribed alerts; manage discounts.
5. Sign in as **courier** and use **I have arrived (demo)**.
6. Sign in as the original **customer** to see the delivery/pickup code in Orders. For home delivery, the **courier** enters the code; for collection, the **admin** enters the pickup code.
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


## New features: shop-to-shop transfers, delivery quotes, low stock

**Inter-store transfer (demo):** Select an unavailable EU size on a branch's
product page and choose **Request from another SneakerHub store**. Pick a source
branch with available stock. Customer sees the request in **Profile > My sneaker
transfers**. Admin sees it in **Stock > Store transfer requests** and can
approve/reserve one pair, mark it as arrived at the destination, reject the
request, or cancel an approved request to return stock to the source. Source
stock is decremented only when an admin approves; destination stock increases
only when an admin confirms arrival. All transitions are transactional and
stored in SQLite. Customer receives in-app notifications, not real-time courier
tracking or a confirmed shipping promise.

**Estimated delivery for Almaty:** In **Cart > Checkout**, choose **Home
delivery** and one of the eight Almaty districts. The app requests the
preliminary fee and 1–3 day estimate from `GET /delivery/estimate`. Same-
district orders get a 400 KZT discount from the illustrative district tariff.
The server independently calculates the delivery fee again and adds it to the
order total. **Pickup** has no shipping fee. Check **Orders** for the fee, ETA
and final total. These rates/dates are fabricated educational examples, not
live courier prices or promised delivery timeframes.

**Low-stock warnings:** In a store's catalogue, EU sizes with one or two
pairs left show a highlighted warning. Product details also display exactly
how many units of the selected size remain in that branch. They update from
per-branch stock stored by the API; do not interpret them as live physical
inventory at any real retailer.

**New endpoints:**
- `GET /delivery/estimate?district=Almaly&store_id=1`
- `POST /transfers` (customer, source/destination/product/EU size)
- `GET /transfers` (customer's own or admin's full list)
- `PATCH /admin/transfers/{id}` (approved/completed/rejected/cancelled)
- `POST /orders` with `delivery_district` for home delivery (server recalculates fee)

To demonstrate, use the same three built-in customer/admin/courier accounts.
The transfers are an administrative **simulation**, not actual physical goods
transported between shops.

## Store API endpoints

- `GET /stores`, `GET /stores/{id}` (profiles + 3 illustration photos)
- `GET /stores/{id}/products`, `GET /stores/{id}/products/{product_id}` (size quantities per branch)
- `GET /products/{id}/availability?size=42` (compare other branches)
- `POST /stores/{id}/restock-alerts` (customer subscription for a sold-out size)
- `GET /restock-alerts`, `DELETE /restock-alerts/{store_id}/{product_id}/{size}`
- `POST /admin/store-supplies` (restock a branch; alert waiting customers)
- `POST /orders` accepts optional `store_id` and `fulfillment: delivery|pickup`
- `PATCH /admin/orders/{id}` accepts `ready_for_pickup` for a prepared pickup order
- `POST /admin/orders/{id}/pickup` verifies the one-time customer code
