# FINAL.docx evaluation checklist (100 points + 10 bonus)

This checklist follows the instructor's scoring categories and distinguishes code from verified device behavior.

| Area | Weight | Implementation | Still needs demonstration |
| --- | ---: | --- | --- |
| Architecture | 15 | Separated lib/models, lib/providers, lib/screens, lib/widgets; public repository with progressive commits | Run flutter analyze, explain code structure |
| UI & flow | 20 | Tabs, Navigator product detail, pull-to-refresh, responsive grid | Test a small phone and tablet, confirm zero overflow |
| Global state | 20 | flutter_bloc/Cubit, context.watch in build, context.read in callbacks; cart and favorite badges | Live screen-to-screen synchronization |
| REST API | 20 | Async HTTP, typed Product.fromJson, loading/error/retry; FastAPI/SQLite demo | Deploy server to a public HTTPS cloud URL and run on device |
| Persistence | 15 | shared_preferences: load theme before runApp; JSON cart and favorite cache | Force quit app and reopen on device; confirm values |
| Defense | 10 | Demo instructions in README and DEFENSE.md | 3-minute live presentation and 2 code questions |
| Bonus | +10 | Debounced catalog search | Secure storage, deep linking and custom icon/splash not yet implemented |

## Device verification script

1. Start the backend or configure a public HTTPS REST API using --dart-define=API_BASE_URL=...
2. Launch Flutter, confirm loading, products and real images.
3. Disconnect the backend, pull to refresh and verify Error + Retry. Restore the backend and tap Retry.
4. Open a product and navigate back; change size and add it to cart; verify cart badge.
5. Mark favorite and visit Favorites; verify saved badge.
6. Open Profile, change Light/Dark theme, kill the app, launch again. Verify theme.
7. Kill and relaunch after adding a cart item; log in and verify saved cart.
8. Test narrow phone and large tablet sizes; run flutter analyze and flutter test.

## Important limitations

Cloud deployment, platform device testing, true push notifications, automatic GPS courier tracking and payments require further work. SQLite on the local demo server is not itself a hosted cloud REST API. A local server or localhost URL does not satisfy the cloud hosting condition.
