# Thunder ⚡️

A powerful Flutter debug overlay for monitoring network requests in real-time. Thunder provides a convenient slide-out panel that shows all network interactions from your Dio HTTP clients.

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
- 📈 **Network Monitoring** - Track all requests and responses from Dio instances
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
  thunder: ^1.0.0  # Replace with actual version
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Setup

Wrap your app with the `Thunder` widget to start monitoring network requests:

```dart
import 'package:thunder/thunder.dart';
import 'package:dio/dio.dart';

void main() {
  // Your Dio instances
  final dio1 = Dio();
  final dio2 = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

  runApp(MyApp(dio1: dio1, dio2: dio2));
}

class MyApp extends StatelessWidget {
  final Dio dio1;
  final Dio dio2;

  const MyApp({required this.dio1, required this.dio2, super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'My App',
    home: const HomePage(),
    builder: (context, child) => Thunder(
      dio: [dio1, dio2],
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
```

### Alternative Setup

You can also add the Thunder interceptor directly to your Dio instance:

```dart
final Dio jsonPlaceholderDio = Thunder.addDio(
  Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com')),
);
```

### How to Use

1. Run your app in debug mode
2. Tap the green handle on the left side of the screen to reveal the Thunder panel
3. Make network requests in your app to see them appear in the panel
4. Use the search button to find specific requests
5. Use the filter button to sort requests
6. Use the delete button to clear all logs

## Configuration

Thunder can be customized with these parameters:

```dart
Thunder(
  // List of Dio instances to monitor
  dio: [dio1, dio2],

  // Optional: Enable/disable the overlay (defaults to kDebugMode)
  enable: true,

  // Optional: Animation duration for the slide-out panel
  duration: const Duration(milliseconds: 250),

  // Optional: Color of the overlay
  color: Colors.green,

  // Required: Your app's main widget
  child: yourAppWidget,
);
```

## How It Works

Thunder attaches to your Dio instances and intercepts all network requests and responses. The data is displayed in a user-friendly interface that can be accessed by tapping the handle on the side of your app.

The overlay shows:

- Request method (GET, POST, PUT, DELETE, etc.)
- URL
- Status code
- Response time
- Request and response headers
- Request and response bodies
- HTML response body

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
