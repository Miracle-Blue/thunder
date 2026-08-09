## 1.1.0-dev.6

- Interceptors can now be turned off: a disabled interceptor is a pure pass-through — traffic flows unchanged and nothing is collected or shown in the panel
  - `Thunder.middlewareEnabled` pauses/resumes HTTP recording at runtime
  - `Thunder.socketClient(enabled: false)` / `Thunder.webSocketInterceptor(enabled: false)` create silenced socket interceptors; `ThunderWebSocketInterceptor.enabled` is mutable for runtime toggling
- The shared HTTP middleware is now app-lifetime: it is no longer reset when the overlay unmounts, so the captured tear-off and the toggle always address the same instance

## 1.1.0-dev.5

- Socket session detail screen: a scroll-to-bottom button now appears when the timeline is scrolled away from the newest event

## 1.1.0-dev.4

- HTTP search fixed: logs that arrived or completed while a search was active were silently lost or leaked into the filtered view; search now filters a live view of the canonical list (same pattern as the Socket tab)
- Middleware now captures every exception, not just `ApiClientException` — a throwing handler no longer leaves the row spinning forever
- `sendBytes` fixed: it measured the stringified byte list (~4-5x inflated) instead of the request body bytes
- Copying a still-loading log or a log with a non-`ApiClientException` error no longer crashes; duplicate `Status:` line removed
- Secure lock icon now renders for `https` requests (the check could never match before)
- Sorting is deterministic: `null` fields sort last instead of comparing against `DateTime.now()`/`Duration.zero`
- Rebuild scope narrowed: a log event now rebuilds only its own tab's list instead of the whole logs screen (navbar, TabBar and both tabs)
- `RepaintBoundary` added around the host app and the sliding panel, so opening/dragging the overlay no longer repaints the application
- `LogButton` converted to a `StatelessWidget`; theme colors and status code resolved once per row build; `MediaQuery.sizeOf` used instead of full `MediaQuery` subscriptions
- Memory capped: at most 1000 HTTP logs, socket sessions and per-session timeline events are retained (oldest dropped); previously everything grew unbounded
- `SocketClient` applies a 30-second default dial timeout when `connectTimeout` is null — a never-settling dial no longer wedges the reconnect loop or makes `close()` hang forever
- JSON pretty-printing works on web: `compute` replaces `Isolate.spawn` (which threw `UnsupportedError` in browsers)
- Detail screens no longer require a `Material` ancestor (root `InkWell` replaced with `GestureDetector`)
- HTTP core test coverage added (middleware, search, sort, copy); README and pubspec description updated from the removed Dio API to the actual `package:http` middleware setup

## 1.1.0-dev.3

- Overlay screen backgrounds now blend with `Color.lerp` for a smoother, less flat panel look
- `CopyableText` rendering refined with tighter line-height and letter-spacing

## 1.1.0-dev.2

- Fixed a "setState()/markNeedsBuild() called during build" crash that occurred when a network request or WebSocket connection was started from a widget's `initState`/build; log notifications emitted during the build phase are now deferred to the end of the frame

## 1.1.0-dev.1

- WebSocket support added
- `SocketClient` added — a reconnecting WebSocket client built on `web_socket_channel ^3.0.3` (`connect`/`send`/`close`, broadcast `messages` and `states` streams, indefinite auto-reconnect, `reconnectInterval`/`connectTimeout`/`pingInterval`/`protocols`/`headers`)
- `Thunder.socketClient` and `Thunder.webSocketInterceptor` added to the public API, along with the `SocketState` sealed hierarchy and the `ThunderWebSocketLog` event model
- Socket tab added to the overlay with per-connection session rows and a live timeline detail screen (sent/received frames, state and error events, long-press to copy, transcript copy)
- Toolbar made tab-aware: search and clear act on the visible section; sorting stays HTTP-only
- HTTP logs no longer duplicate rows (loading and completed entries now share one row)
- `ThunderLogNotifier` added as a standalone `ChangeNotifier` for network logs
- `curl_extension.dart` and `middleware_extensions.dart` exported from the public API
- `ThunderColors` theming utility added for light/dark color support
- Thunder overlay UI is now fully dark regardless of the host app theme: dark scaffolds, toolbar, handle, HTTP method card tints, buttons, snackbar and JSON viewer, with the panel theme no longer inheriting the host app's text colors
- `web_socket_channel` and `logbook` added as dependencies

## 1.0.2-dev.7

- Pub score fixed

## 1.0.2-dev.6

- Pub score fixed

## 1.0.2-dev.5

- Meta package removed

## 1.0.2-dev.4

- Curl command generation improved in the log button

## 1.0.2-dev.3

- code formatted

## 1.0.2-dev.2

- Fix the issue of the pub score

## 1.0.2-dev.1

- Thunder logic changed from dio to http client

## 0.2.3

- Duplicate logs bug fixed

## 0.2.2

- Adding interceptor using Thunder.addDio(dio) method not showing logs bug fixed

## 0.2.1

- Added CopyableText widget to fix system context menu error in console logs

## 0.2.0

- Thunder.addDio(dio) method added
- Thunder.getDiosHash method added
- Thunder.getInterceptor method deprecated use Thunder.addDio(dio) instead

## 0.1.1

- Fix the issue of the pub score

## 0.1.0

- Dart version 3.8.0

## 0.0.9

- Fix the issue of the accessing Thunder.getInterceptor before the widget is created
- Icon color changed to black
- Packages version replaced with any

## 0.0.8

- Copy log data to clipboard bug fix

## 0.0.7

- Streamlined interceptor access; Screenshots changed

## 0.0.6

- Enable curly braces in flow control structures

## 0.0.5

- Fix the issue of the pub score

## 0.0.4

- Update image dimensions in the README.md

## 0.0.3

- Fix the issue of the pub score

## 0.0.2

- Pub score fixed
