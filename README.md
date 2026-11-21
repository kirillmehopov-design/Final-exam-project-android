# SneakerHub — Flutter Final Exam (Lab 11 baseline)

This branch **starts from the real Lab 11 source** in `kirillmehopov-design/lab10-android`, not from the earlier SneakerHub implementation. Earlier final work remains available on its original branches. The `main` branch is unchanged.

## Implemented in this branch

- Cloud catalog from `https://fakestoreapi.com/products` with loading / success / network-error-and-retry views
- Type-safe parsing of numeric prices (`(json['price'] as num).toDouble()`)
- Provider / ChangeNotifier cart, live quantity badge and multi-screen updates
- Product detail, Hero transition, 3-page photo gallery, and sharing a **link string** (not configured OS deep-link reception)
- Dark / light theme restored before `runApp()`
- Local username and offline notes (add / check / delete)
- **New for Final:** cart persisted using SharedPreferences JSON and restored before `runApp()`
- Separate widget, data-model, provider and API tests

Important: the current API contains **general merchandise, not a sneaker-only inventory**. The branding is SneakerHub, but the catalog still needs to be converted to sneaker inventory before it can be described as a finished sneaker store.

## Run in Chrome (the preferred preview device)

From a newly downloaded branch ZIP, open PowerShell in the directory containing `pubspec.yaml`:

```powershell
flutter create --platforms=android,web .
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run -d chrome
```

The scaffold command fills in the generated Android/Web files that are not committed in the Lab 11 starting source. It does not delete the app code.

To demonstrate mobile force-quit / reopen, use a physical Android phone or emulator. **Chrome refresh alone does not satisfy the mobile demo requirement.**

## Required grading checklist (FINAL(1).docx)

| Criterion | Current status |
| --- | --- |
| models/providers/screens/widgets separation | Implemented |
| 3+ screens with Navigator | Implemented |
| Responsive overflow-free screens at small & large sizes | Not yet verified on devices |
| Hero and photo PageView | Implemented |
| Global Provider + live badges | Implemented |
| Real cloud HTTP API | Fake Store API integrated; live availability/CORS must be tested |
| Loading / Success / Error + Retry | Implemented |
| Theme stored and preloaded | Implemented |
| Cart and notes persisted | Implemented; physical kill-and-reopen still needs verification |
| 10+ progressive commits + README | Git history exists; verify grading history rules |
| 3-minute mobile live demo and questions | Must perform in person |
| Bonus secure storage/deep linking/custom splash | Not yet implemented |
| Bonus debounced search | Not yet implemented |

## Planned after the mandatory checks

- Sneaker inventory instead of generic Fake Store products
- Debounced search, filters and more responsive layout testing
- Map of sneaker stores (real or demo branches, clearly labeled)
- Offers/discount notifications, delivery handoff code and stock management
- Optional server/database for real orders and inventory

## Defense notes

1. In `main.dart`, SharedPreferences providers are loaded **before** `runApp()` to avoid the wrong initial theme and to restore the cart.
2. `ProductApi.fetchProducts()` sends an HTTP GET, validates status codes, decodes JSON, and raises readable errors.
3. `Product.fromJson()` accepts integer or decimal JSON prices safely.
4. `CartProvider` extends `ChangeNotifier`; `notifyListeners()` updates badge/cart screens. `context.read` is used for clicks, and `context.select` / `Consumer` for reactive UI.
5. In Notes & Settings, the name, theme and notes persist as small local key-value data. Passwords must **not** be stored in SharedPreferences.

**Verification:** Code changes were committed. The Flutter SDK is not present in the assistant's execution environment, so local Android/Chrome execution and CI results are separate checks, not claims of verified success.
