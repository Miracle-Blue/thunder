import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../common/extension/middleware_extensions.dart';
import '../../common/utils/app_colors.dart';
import '../controllers/thunder_logs_controller.dart';
import '../controllers/thunder_overlay_controller.dart';
import '../screens/thunder_logs_screen.dart';

/// A debug overlay widget that displays network logs and provides debugging tools.
///
/// The Thunder widget creates a slide-out panel that shows network requests and responses
/// from provided Dio instances. This is particularly useful during development to monitor
/// API interactions, debug network issues, and analyze app behavior.
///
/// Features:
/// - Displays network requests and responses from Dio instances
/// - Provides filtering and search capabilities for logs
/// - Allows clearing of logs
/// - Can be easily toggled with a handle on the side of the screen
/// - Only active in debug mode by default
/// ------------------------------------------------------------------------------------------------
/// - [enabled]: Whether to enable the overlay (defaults to kDebugMode)
/// - [dio]: List of Dio instances to monitor for network activity
/// - [duration]: Animation duration for showing/hiding the overlay
/// - [child]: The main application widget that Thunder will wrap
///
/// Example:
/// ```dart
/// class MyApp extends StatelessWidget {
///   const MyApp({super.key});
///
///   @override
///   Widget build(BuildContext context) => MaterialApp(
///     title: 'Flutter Demo',
///     home: const MyHomePage(title: 'Flutter Demo Home Page'),
///     builder:  (context, child) => Thunder(
///       dio: [_httpDio, _mainDio],
///       child: child ?? SizedBox.shrink(),
///     ),
///   );
/// }
/// ```
///
/// You can also use Thunder without initializing the widget by directly adding the interceptor to a Dio instance:
///
/// ```dart
/// // This will work even before a Thunder widget is created
/// final dio = Dio()..interceptors.add(Thunder.getInterceptor);
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
  /// When false, the Thunder widget simply returns the child without any overlay functionality.
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

  /// Adds a Dio instance to be tracked by Thunder
  ///
  /// Example:
  /// ```dart
  /// Thunder.addDio(dio);
  /// ```
  ///
  /// Optionally, you can use the returned [Dio] instance
  /// Example:
  /// ```dart
  /// final dio = Thunder.addDio(Dio());
  /// ```
  static ApiClientMiddleware get middleware =>
      ThunderLogsController.getMiddleware();

  /// Utility to see the dio instances that are being monitored.
  ///
  /// Example:
  /// ```dart
  /// log(Thunder.getDiosHash);
  /// ```
  // static String get getDiosHash => ThunderLogsController.getDiosHash;

  @override
  State<Thunder> createState() => _ThunderState();
}

class _ThunderState extends ThunderOverlayController {
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
                          MaterialPage<void>(
                            child: ThunderLogsScreen(),
                          ),
                        ],
                        onDidRemovePage: (page) => log('ON DID REMOVE PAGE'),
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
                const Align(
                  alignment: Alignment(0, -0.8),
                  child: Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Search button - toggles search functionality in logs
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: ThunderLogsController.toggleSearch,
                            icon: Icon(Icons.search_rounded),
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Filter button - changes sort order of logs
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: ThunderLogsController.onSortLogsTap,
                            icon: Icon(Icons.filter_list_rounded),
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Delete button - clears all logs
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: ThunderLogsController.onDeleteAllLogsTap,
                            icon: Icon(Icons.delete),
                            color: Colors.black,
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
                    color: AppColors.mainColor,
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
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
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
                // Calculate width of overlay panel, capped at 400 or 99% of screen width
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
                        child:
                            SizedBox(width: width, child: _materialContext()),
                      ),
                    ],
                  ),
                );
              },
            );
}
