# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Analyze code (must pass before committing)
fvm flutter analyze

# Format code (80-char line width)
fvm dart format . -l 80

# Set up pre-commit hook (run once after cloning)
git config core.hooksPath .githooks

# Run example app
cd example && flutter run
```

The pre-commit hook runs `dart format`, `flutter analyze`, and `pana` automatically. Commits fail if analyze finds issues.

## Architecture

**Thunder** is a Flutter HTTP network inspector — a debug overlay that intercepts and displays network requests in a slide-out panel. It integrates with the `http` package via a middleware pattern.

### Data flow

1. App wraps its widget tree in `Thunder(child: ...)` and passes `Thunder.middleware` to its HTTP client.
2. Each HTTP request flows through `ThunderMiddleware.call()` (a `Middleware` function type from `middleware_extensions.dart`).
3. The middleware captures request/response/error and invokes `onNetworkActivity`, which pushes a `ThunderNetworkLog` to `ThunderLogsController.networkLogs` and fires `logNotifier`.
4. `logNotifier` (a `ChangeNotifier`) triggers a rebuild of `ThunderLogsScreen`.
5. The panel opens/closes via drag gesture handled by `ThunderOverlayController` with `AnimationController`.

### Key types

| Type                                  | File                                                  | Role                                                                        |
| ------------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------- |
| `Thunder`                             | `feature/widgets/thunder_overlay.dart`                | Entry widget; exposes static `middleware` and `webSocketMiddleware` getters |
| `ThunderNetworkLog`                   | `common/models/thunder_network_log.dart`              | Immutable log entry (request + response + error + timing)                   |
| `ThunderMiddleware`                   | `common/utils/thunder_interceptor.dart`               | Implements the `Middleware` type; wraps HTTP handler                        |
| `ThunderLogsController`               | `feature/controllers/thunder_logs_controller.dart`    | Singleton owning log lists, search state, sort type                         |
| `ThunderOverlayController`            | `feature/controllers/thunder_overlay_controller.dart` | Base class for `_ThunderState`; owns `AnimationController` and drag logic   |
| `ApiClientRequest/Response/Exception` | `common/extensions/middleware_extensions.dart`        | Extension types wrapping the `http` package primitives                      |
| `ThunderColors` / `LoggerColors`      | `common/utils/logger_colors.dart`                     | Theme-aware color provider (light/dark)                                     |
| `Helpers`                             | `common/utils/helpers.dart`                           | `formatBytes()`, `copyAndShowSnackBar()`, `getStatusCode()`                 |

### Widget tree

```
Thunder (StatefulWidget)
└─ _ThunderState (extends ThunderOverlayController)
    ├─ GestureDetector (drag to open/close panel)
    ├─ Handle (colored tab on left edge)
    └─ AnimatedBuilder → slide-out panel
        └─ ThunderLogsScreen (CupertinoPageScaffold)
            ├─ CupertinoNavigationBar (title / search toggle)
            └─ ListView → LogButton → ThunderLogDetailScreen
```

### Code conventions

- **80-character line limit** enforced by the linter.
- **`always_use_package_imports`** — use `package:thunder/...` imports, never relative `../` imports inside `lib/`.
- All public members require a doc comment (`public_member_api_docs: true`).
- Strict type inference enabled (`strict-casts`, `strict-raw-types`, `strict-inference`).
- WebSocket support lives in `ThunderWSLogNotifier` / `log_ws_button.dart` and is still experimental.
