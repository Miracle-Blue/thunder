# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Thunder is a Flutter package that provides a powerful debug overlay for monitoring network requests in real-time. It creates a slide-out panel that displays network interactions from Dio HTTP clients, offering debugging capabilities during development.

## Key Architecture

### Core Components

- **Thunder Widget** (`lib/src/feature/widgets/thunder_overlay.dart`): Main overlay widget that wraps the app and provides the slide-out debugging panel
- **ThunderInterceptor** (`lib/src/common/utils/thunder_interceptor.dart`): Dio interceptor that captures network requests/responses and converts them to log entries
- **ThunderLogsController** (`lib/src/feature/controllers/thunder_logs_controller.dart`): State management controller that handles log storage, UI updates, and user interactions
- **ThunderNetworkLog** (`lib/src/common/models/thunder_network_log.dart`): Data model representing captured network activity

### Integration Patterns

1. **Widget-based Integration**: Wrap app with `Thunder` widget and pass Dio instances
2. **Manual Integration**: Use `Thunder.addDio(dio)` to add interceptors to specific Dio instances
3. **Singleton Pattern**: ThunderInterceptor uses singleton pattern for managing network activity callbacks

### Architecture Flow

1. Dio instances are registered with Thunder via widget or manual method
2. ThunderInterceptor is added to each Dio instance's interceptors
3. Network requests trigger interceptor callbacks that create ThunderNetworkLog entries
4. Logs are stored in static list and UI is updated via controller setState
5. Overlay provides filtering, searching, and detailed request/response viewing

## Development Commands

### Flutter Commands

```bash
# Run the example app
cd example && flutter run

# Build the package
flutter packages get

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Linting and Code Quality

- The project uses strict analysis options configured in `analysis_options.yaml`
- Key rules: strict-casts, strict-raw-types, public API documentation required
- Line length: 120 characters
- Prefer single quotes, const constructors, and relative imports

## Project Structure

```
lib/
├── src/
│   ├── common/
│   │   ├── extension/          # Utility extensions for core types
│   │   ├── models/             # Data models (ThunderNetworkLog)
│   │   └── utils/              # Core utilities (ThunderInterceptor, helpers)
│   └── feature/
│       ├── controllers/        # State management controllers
│       ├── overlays/           # Dialog overlays (sort dialog)
│       ├── screens/            # Main screens (logs list, log detail)
│       └── widgets/            # UI widgets (Thunder overlay)
└── thunder.dart               # Main export file
```

## Key Implementation Details

### State Management

- Uses singleton pattern for ThunderLogsController to maintain state across widget rebuilds
- Static networkLogs list stores all captured network activity
- Controller manages UI state (search enabled, dialog open, etc.)

### Network Interception

- ThunderInterceptor implements Dio's Interceptor interface
- Tracks request timing using hash code mapping
- Captures request/response data and calculates byte counts
- Handles both successful responses and errors

### UI Features

- Slide-out overlay with animated handle
- Search functionality for filtering logs by URL/baseURL
- Sorting options (by time, response time, endpoint, size)
- Detailed request/response viewer with JSON formatting
- Copy-to-clipboard functionality for curl commands

## Testing and Quality

### Test Coverage

- Main test file: `test/nexus_test.dart`
- Example app demonstrates integration patterns

### Code Style

- Follows Flutter/Dart conventions with strict linting
- Public APIs require documentation
- Prefer const constructors and immutable widgets where possible
- Use relative imports within the package

## Development Notes

- Debug mode only: Thunder overlay is automatically disabled in release builds (kDebugMode)
- Platform support: Android, iOS, Web, macOS, Windows, Linux
- Dependencies: dio (>=5.0.0 <6.0.0), intl, html
- Minimum Dart SDK: ^3.6.0
