import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/extension/middleware_extensions.dart';
import '../../common/utils/colors.dart';
import '../../common/utils/socket_client.dart';
import '../../common/utils/thunder_ws_interceptor.dart';
import '../controllers/thunder_logs_controller.dart';
import '../controllers/thunder_overlay_controller.dart';
import '../screens/thunder_logs_screen.dart';

/// A debug overlay widget that displays
/// network logs and provides debugging tools.
///
/// The Thunder widget creates a slide-out panel
/// that shows network requests and responses
/// from provided ApiClient instances.
/// This is particularly useful during development to monitor
/// API interactions, debug network issues, and analyze app behavior.
///
/// Features:
/// - Displays network requests and responses from ApiClient instances
/// - Records WebSocket traffic in a dedicated Socket tab (see
///   [Thunder.socketClient] and [Thunder.webSocketInterceptor])
/// - Provides filtering and search capabilities for logs
/// - Allows clearing of logs
/// - Can be easily toggled with a handle on the side of the screen
/// - Only active in debug mode by default
/// ----------------------------------------------------------------------------
/// - [enabled]: Whether to enable the overlay (defaults to kDebugMode)
/// - [duration]: Animation duration for showing/hiding the overlay
/// - [child]: The main application widget that Thunder will wrap
///
/// You can use Thunder without initializing the widget
/// by directly adding the middleware to a ApiClient instance:
///
/// ```dart
/// // This will work even before a Thunder widget is created
/// final client = ApiClient(middleware: Thunder.middleware);
/// ```
class Thunder extends StatefulWidget {
  /// Constructor for the [Thunder] class.
  const Thunder({
    required this.child,
    this.enabled = kDebugMode,
    this.duration = const Duration(milliseconds: 250),
    this.color,
    super.key,
  });

  /// Whether to enable the overlay.
  ///
  /// When false, the Thunder widget simply returns
  /// the child without any overlay functionality.
  /// Defaults to [kDebugMode] which means it's only enabled in debug builds.
  final bool enabled;

  /// The duration of the overlay animation.
  ///
  /// Controls how quickly the overlay slides in and out.
  final Duration duration;

  /// The color of the [Thunder].
  ///
  /// Defaults to green.
  final Color? color;

  /// The child widget (the main widget of the app).
  ///
  /// This is typically the root of your application that Thunder will wrap.
  final Widget child;

  /// Add this middleware to your ApiClient instances.
  ///
  /// Example:
  /// ```dart
  /// Thunder.middleware;
  /// ```
  static ApiClientMiddleware get middleware =>
      ThunderLogsController.getMiddleware.call;

  /// Creates a reconnecting [SocketClient] whose whole lifecycle — frames,
  /// state changes and errors — is recorded in Thunder's Socket tab.
  ///
  /// Example:
  /// ```dart
  /// final socket = Thunder.socketClient(
  ///   uri: Uri.parse('wss://echo.websocket.org'),
  /// );
  ///
  /// socket.states.listen(onStateChanged);
  /// socket.messages.listen(onMessage);
  ///
  /// await socket.connect();
  /// socket.send('hello');
  /// ```
  ///
  /// The client reconnects on its own until [SocketClient.close] is called;
  /// closing is final — create a new client to connect again. [headers] and
  /// [pingInterval] only apply on `dart:io` platforms.
  static SocketClient socketClient({
    required Uri uri,
    String? label,
    Iterable<String>? protocols,
    Map<String, Object?>? headers,
    Duration reconnectInterval = const Duration(seconds: 5),
    Duration? connectTimeout,
    Duration? pingInterval,
  }) => SocketClient(
    uri: uri,
    protocols: protocols,
    headers: headers,
    reconnectInterval: reconnectInterval,
    connectTimeout: connectTimeout,
    pingInterval: pingInterval,
    interceptor: ThunderLogsController.socketLogger(uri: uri, label: label),
  );

  /// Creates a logging hook for a self-managed WebSocket connection.
  ///
  /// Use it when you manage your own channel (e.g. `web_socket_channel`,
  /// STOMP, GraphQL subscriptions) and only want the traffic to appear in
  /// Thunder's Socket tab. One interceptor equals one session row.
  ///
  /// Example:
  /// ```dart
  /// final logger = Thunder.webSocketInterceptor(uri: uri);
  ///
  /// logger.logState(const SocketConnecting());
  /// channel.stream.listen(logger.logReceived);
  ///
  /// logger.logSent('hello');
  /// channel.sink.add('hello');
  /// ```
  static ThunderWebSocketInterceptor webSocketInterceptor({
    required Uri uri,
    String? label,
  }) => ThunderLogsController.socketLogger(uri: uri, label: label);

  @override
  State<Thunder> createState() => _ThunderState();
}

class _ThunderState extends ThunderOverlayController {
  // Fixed dark theme for the panel. Built from the dark base (never from
  // the host theme, whose light text colors would leak into the panel) and
  // pinning ThunderColors.dark so the panel is dark regardless of the app.
  static final ThemeData _panelTheme = () {
    final base = ThemeData.dark();
    return base.copyWith(
      extensions: const <ThemeExtension<Object?>>[ThunderColors.dark],
      textTheme: base.textTheme.apply(fontFamily: 'Monospace'),
    );
  }();

  /// Builds the main content of the Thunder overlay panel.
  ///
  /// This includes:
  /// - The logs screen navigation container
  /// - Control buttons for searching, filtering, and clearing logs
  /// - The handle for toggling the overlay
  Widget _materialContext() => Row(
    children: <Widget>[
      // Main overlay content area
      Expanded(
        child: Visibility(
          visible: !dismissed,
          maintainState: true,
          maintainAnimation: false,
          maintainSize: false,
          maintainInteractivity: false,
          maintainSemantics: false,
          child: Material(
            elevation: 0,
            child: DefaultSelectionStyle(
              child: ScaffoldMessenger(
                child: HeroControllerScope.none(
                  child: Navigator(
                    pages: const <Page<void>>[
                      MaterialPage<void>(child: ThunderLogsScreen()),
                    ],
                    onDidRemovePage: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      /// Control panel and handle for toggling the overlay
      Stack(
        children: [
          // Control buttons - only visible when overlay is shown
          if (!dismissed)
            Align(
              alignment: const Alignment(0, -0.8),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search button - toggles search functionality in logs
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: ThunderColors.of(context).surface,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: ThunderLogsController.toggleSearch,
                        icon: const Icon(Icons.search_rounded),
                        color: ThunderColors.of(context).cWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Filter button - changes sort order of HTTP logs;
                    // hidden while the Socket tab is active
                    ValueListenableBuilder<ThunderSection>(
                      valueListenable: ThunderLogsController.activeSection,
                      builder: (context, section, child) => section.isSocket
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: ThunderColors.of(context).surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed:
                                        ThunderLogsController.onSortLogsTap,
                                    icon: const Icon(Icons.filter_list_rounded),
                                    color: ThunderColors.of(context).cWhite,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                    ),
                    // Delete button - clears all logs
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: ThunderColors.of(context).surface,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: ThunderLogsController.onDeleteAllLogsTap,
                        icon: const Icon(Icons.delete),
                        color: ThunderColors.of(context).cWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Toggle handle - always visible on the side of the screen
          Align(
            alignment: const Alignment(0, -0.4),
            child: SizedBox(
              width: handleWidth,
              height: 64,
              child: Material(
                color: widget.color,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16),
                ),
                elevation: 0,
                child: InkWell(
                  onTap: () => controller.toggle(),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(16),
                  ),
                  child: Center(
                    // Rotating chevron that indicates the current state (open/closed)
                    child: RotationTransition(
                      turns: controller.drive(
                        Tween<double>(begin: 0, end: 0.5),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: ThunderColors.of(context).cBlack,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) =>
      // If overlay is disabled, just return the child widget
      !widget.enabled
      ? widget.child
      : LayoutBuilder(
          builder: (context, constraints) {
            final biggest = constraints.biggest;
            // Calculate width of overlay panel,
            // capped at 400 or 99% of screen width
            final width = math.min<double>(500, biggest.width * 0.99);

            return GestureDetector(
              // Handle drag gestures to manually slide the overlay
              onHorizontalDragUpdate: dismissed
                  ? null
                  : (details) => onHorizontalDragUpdate(details, width),
              onHorizontalDragEnd: dismissed ? null : onHorizontalDragEnd,
              child: Stack(
                children: <Widget>[
                  // The main app content
                  widget.child,
                  // Semi-transparent barrier behind the overlay when open
                  if (!dismissed)
                    AnimatedModalBarrier(
                      color: controller.drive(
                        ColorTween(
                          begin: Colors.transparent,
                          end: Colors.black.withAlpha(127),
                        ),
                      ),
                      dismissible: true,
                      semanticsLabel: 'Dismiss',
                      onDismiss: () => controller.hide(),
                    ),
                  // The sliding overlay panel
                  PositionedTransition(
                    rect: controller.drive(
                      RelativeRectTween(
                        begin: RelativeRect.fromLTRB(
                          handleWidth - width,
                          0,
                          biggest.width - handleWidth,
                          0,
                        ),
                        end: RelativeRect.fromLTRB(
                          0,
                          0,
                          biggest.width - width,
                          0,
                        ),
                      ),
                    ),
                    child: Theme(
                      data: _panelTheme,
                      child: SizedBox(width: width, child: _materialContext()),
                    ),
                  ),
                ],
              ),
            );
          },
        );
}
