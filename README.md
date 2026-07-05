# Thunder ⚡️

A powerful Flutter debug overlay for monitoring network requests in real-time. Thunder provides a convenient slide-out panel that shows all network interactions from your `package:http`-based clients and WebSockets.

<div style="display: flex; flex-direction: row; flex-wrap: wrap; gap: 10px;">
  <img src="https://github.com/Miracle-Blue/thunder/raw/main/screenshots/screenshot_1.png" width="200" alt="Thunder Overview">
  <img src="https://github.com/Miracle-Blue/thunder/raw/main/screenshots/screenshot_2.png" width="200" alt="Thunder Request Details">
  <img src="https://github.com/Miracle-Blue/thunder/raw/main/screenshots/screenshot_3.png" width="200" alt="Thunder Response View">
  <img src="https://github.com/Miracle-Blue/thunder/raw/main/screenshots/screenshot_4.png" width="200" alt="Thunder Search Feature">
  <img src="https://github.com/Miracle-Blue/thunder/raw/main/screenshots/screenshot_5.png" width="200" alt="Thunder Search Feature">
  <img src="https://github.com/Miracle-Blue/thunder/raw/main/screenshots/screenshot_6.png" width="200" alt="Thunder Search Feature">
</div>

## Features

- 📱 **Simple Integration** - Add a single widget to your app
- 📈 **Network Monitoring** - Track all requests and responses via a middleware for `package:http`-based clients
- 🔌 **WebSocket Monitoring** - Reconnecting `SocketClient` plus a Socket tab with a live per-connection event timeline
- 🔎 **Search & Filter** - Easily find specific network calls
- 🗑️ **Clear Logs** - One-tap to remove all logs
- 👆 **Interactive UI** - Slide-out panel with intuitive controls
- 🛠️ **Debug Mode Only** - Automatically disabled in release builds
- 📊 **Request Details** - View headers, payloads, and responses

## Platform Support

| Android |  iOS  | MacOS |  Web  | Linux | Windows |
| :-----: | :---: | :---: | :---: | :---: | :-----: |
|✅|✅|✅|✅|✅|✅|

## Installation

Add Thunder to your `pubspec.yaml`:

```yaml
dependencies:
  thunder: ^1.1.0-dev.4
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Setup

Wrap your app with the `Thunder` widget and plug `Thunder.middleware` into
your `package:http`-based client's middleware chain. Thunder exports the
middleware types (`ApiClientMiddleware`, `ApiClientHandler`,
`ApiClientRequest`, `ApiClientResponse`); the client itself is yours — see
the [example app's `ApiClient`](https://github.com/Miracle-Blue/thunder/blob/dev/example/lib/api_client.dart)
for a complete implementation:

```dart
import 'package:thunder/thunder.dart';

void main() {
  final client = ApiClient(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    middlewares: <ApiClientMiddleware>[Thunder.middleware],
  );

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.client, super.key});

  final ApiClient client;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'My App',
    home: const HomePage(),
    builder: (context, child) =>
        Thunder(child: child ?? const SizedBox.shrink()),
  );
}
```

`Thunder.middleware` works even before a `Thunder` widget is created, so the
client can be constructed anywhere — requests made before the overlay mounts
are captured once it appears.

### How to Use

1. Run your app in debug mode
2. Tap the handle on the left side of the screen to reveal the Thunder panel
3. Make network requests in your app to see them appear in the panel
4. Use the search button to find specific requests
5. Use the filter button to sort requests
6. Use the delete button to clear all logs

## WebSocket Monitoring

Thunder ships a reconnecting WebSocket client built on
[`web_socket_channel`](https://pub.dev/packages/web_socket_channel) `^3.0.3`.
Create it through `Thunder.socketClient` and the whole connection lifecycle —
sent/received frames, state transitions, errors — is recorded as a session in
the **Socket** tab of the overlay:

```dart
final socket = Thunder.socketClient(
  uri: Uri.parse('wss://echo.websocket.org'),
  label: 'Echo demo',                              // optional session name
  reconnectInterval: const Duration(seconds: 3),
  connectTimeout: const Duration(seconds: 10),
);

socket.states.listen((state) => print('state: $state'));
socket.messages.listen((message) => print('message: $message'));

await socket.connect();
socket.send('hello');

// close() is final: the client stops reconnecting and both streams
// complete. Create a new client to connect again.
await socket.close();
```

The client reconnects indefinitely (spaced by `reconnectInterval`) until
`close()` is called, and `connect()` never throws on a failed dial — watch
the `states` stream (`SocketConnecting`, `SocketConnected`,
`SocketReconnecting`, `SocketDisconnected`) for the outcome.

### Monitoring a self-managed WebSocket

If you already manage your own channel (plain `web_socket_channel`, STOMP,
GraphQL subscriptions, ...), attach only the logging hook. One interceptor
equals one session row in the Socket tab:

```dart
final logger = Thunder.webSocketInterceptor(uri: uri);
final channel = WebSocketChannel.connect(uri);

logger.logState(const SocketConnecting());
await channel.ready;
logger.logState(const SocketConnected());

channel.stream.listen(logger.logReceived);

logger.logSent('hello');
channel.sink.add('hello');
```

### The Socket tab

The overlay's **HTTP** and **Socket** tabs work independently, each with its
own empty state. The Socket tab shows one row per connection — URI, a live
state dot, `↑ sent` / `↓ received` counters, total bytes and the last
activity time. Tapping a session opens its chronological timeline where
frames render as aligned cards and state/error events as centered pills.
Long-press any timeline row to copy its message text; the floating button
copies the whole session transcript. The toolbar is tab-aware: search
filters the visible section and the delete button clears only it.

> **Platform note:** `headers` and `pingInterval` only apply on `dart:io`
> platforms (Android, iOS, desktop) — browser WebSockets don't support them.

## Configuration

Thunder can be customized with these parameters:

```dart
Thunder(
  // Optional: Enable/disable the overlay (defaults to kDebugMode)
  enabled: true,

  // Optional: Animation duration for the slide-out panel
  duration: const Duration(milliseconds: 250),

  // Optional: Color of the handle
  color: Colors.green,

  // Required: Your app's main widget
  child: yourAppWidget,
);
```

## How It Works

Every request flowing through `Thunder.middleware` is captured — request,
response, error and timing — and displayed in a user-friendly interface that
can be accessed by tapping the handle on the side of your app.

The overlay shows:

- Request method (GET, POST, PUT, DELETE, etc.)
- URL
- Status code
- Response time
- Request and response headers
- Request and response bodies (HTML bodies are detected and flagged, not rendered)

## Example Project

For a complete working example, check the [example](https://github.com/Miracle-Blue/thunder/blob/dev/example/lib/main.dart) directory.

## Contributing

Contributions are welcome! If you find a bug or want a feature, please:

1. Check if an issue already exists
2. Create a new issue if needed
3. Fork the repo
4. Create your feature branch (`git checkout -b feature/amazing-feature`)
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/Miracle-Blue/thunder/blob/main/LICENSE) file for details.
