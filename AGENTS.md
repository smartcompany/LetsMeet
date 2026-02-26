# AGENTS.md

## Cursor Cloud specific instructions

### Project overview

LetsMeet (branded "Gather" on web) is a Flutter cross-platform social meetup app targeting the Korean market. This repo is the **client only**; the backend API is hosted externally at `https://lets-meet-server.vercel.app/api` (separate repository). Firebase (Auth, Firestore, FCM) and Supabase (image storage) are cloud-hosted dependencies.

### Running the app (web)

In this headless Linux cloud environment, the web target is the only runnable platform.

```
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

Then open `http://localhost:8080` in Chrome. The app loads a splash screen, then the home page with meetup listings.

### Lint / analyze

```
flutter analyze
```

All current issues are `info`-level (deprecation warnings, style suggestions). There are no errors.

### Tests

```
flutter test
```

The only test (`test/widget_test.dart`) is a skipped smoke test because Firebase mocks are not yet set up.

### Build (web)

```
flutter build web
```

Produces output in `build/web/`. Wasm compatibility warnings from third-party packages (`share_plus`, `kakao_map_sdk`, `win32`) are expected and can be ignored.

### Key gotchas

- **Flutter SDK**: Must be installed at `/opt/flutter` and added to `PATH`. The update script handles `flutter pub get` automatically.
- **`share_lib` Git dependency**: Fetched from `https://github.com/smartcompany/flutter_share_lib.git` (branch `main`). If this repo is private or inaccessible, `flutter pub get` will fail. See `SUBMODULE_GUIDE.md` for local override instructions.
- **Authentication**: Social login (Kakao, Google, Apple) requires external OAuth setup. The chat and profile tabs require login. The home and feed tabs are accessible without login.
- **No local backend**: All API calls go to the external Vercel-hosted backend. There is no `docker-compose` or local server to run.
- **Korean locale**: Most UI text, comments, and documentation are in Korean.
