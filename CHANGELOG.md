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
