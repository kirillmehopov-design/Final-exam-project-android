# SneakerHub V2 — UX/UI and device test notes

The new experience is not just changed colors. The redesign uses original
acid-lime + graphite editorial identity, a working promo bar, a large campaign
hero, three interactive category edits (Lifestyle / Running / Streetwear),
featured products carousel, consistent stock-aware sneaker cards, modern
profile sections, compact mobile store cards, a new shopping bag and a
functional footer **© SneakerHub 2026** with navigation and Back to top.

Retail inspiration: editorial layouts in Nike/END. Design assets/code are not
copied from those sites. The demo's Unsplash product photos may not correspond
to exact named products.

## Verify manually
- 320, 390, 768, 1440px viewport widths, light/dark mode, keyboard navigation.
- Sign in, open catalog, tap category, search, reset filters, open a product.
- Confirm PageView swipe, size, cart badge, compare branches and buy CTA.
- 10 map markers, store photo gallery, per-branch stock, pickup/delivery.
- Account alerts, theme and cart persistence after force-quit/relaunch.
- Deep link on Android with:
  `adb shell am start -a android.intent.action.VIEW -d "narxoz://store/product/1"`

## Run both terminals on Windows
Terminal 1 in `backend`:
```powershell
py -m pip install -r requirements.txt
py -m uvicorn app:app --reload --host 127.0.0.1 --port 8000
```
Terminal 2 in root:
```powershell
flutter create --platforms=android,web .
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

CI verifies analyzer, widget/API tests and Web compilation. Actual interactive
rendering with loaded remote photos is not fully validated by CI.
