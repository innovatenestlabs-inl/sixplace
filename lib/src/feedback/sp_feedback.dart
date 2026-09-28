import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/sp_theme.dart';

/// Semantic intent used by Sixplace feedback surfaces.
enum SPFeedbackType {
  /// Informational feedback.
  info,

  /// Successful completion.
  success,

  /// A warning that deserves attention.
  warning,

  /// An error or destructive outcome.
  error,
}

/// Controls the visual appearance of transient feedback messages.
@immutable
class SPFeedbackStyle {
  /// Creates a feedback style.
  const SPFeedbackStyle({
    this.behavior = SnackBarBehavior.floating,
    this.showCloseIcon = true,
    this.margin,
    this.padding,
    this.width,
    this.elevation,
  });

  /// How a message is positioned by [ScaffoldMessenger].
  final SnackBarBehavior behavior;

  /// Whether a close icon is shown on the message.
  final bool showCloseIcon;

  /// Optional outer margin used by floating snack bars.
  final EdgeInsetsGeometry? margin;

  /// Optional content padding.
  final EdgeInsetsGeometry? padding;

  /// Optional fixed width for floating snack bars.
  final double? width;

  /// Optional material elevation.
  final double? elevation;
}

/// Handle returned by [SPFeedback.showLoading].
///
/// Calling [close] is idempotent and removes only the loader created for this
/// handle; it never pops an unrelated application route.
class SPFeedbackLoaderHandle {
  SPFeedbackLoaderHandle._(this._navigator, this._route);

  final NavigatorState _navigator;
  final Route<void> _route;
  bool _closed = false;

  /// Whether the loader route is still active.
  bool get isVisible => !_closed && _route.isActive;

  /// Removes the loader route if it is still present.
  void close() {
    if (_closed) return;
    _closed = true;
    if (_route.isActive) {
      _navigator.removeRoute(_route);
    }
  }
}

/// A reusable blocking progress surface for embedded application workflows.
class SPBlockingLoader extends StatelessWidget {
  /// Creates a centered progress indicator with an optional message.
  const SPBlockingLoader({
    super.key,
    this.message,
    this.progressIndicator,
    this.padding = const EdgeInsets.all(24),
  });

  /// Optional explanatory message.
  final String? message;

  /// Optional custom progress widget.
  final Widget? progressIndicator;

  /// Padding around the loader content.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final text = message?.trim();
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Card(
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                progressIndicator ?? const CircularProgressIndicator(),
                if (text != null && text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cross-platform transient messages, alerts and blocking loaders.
///
/// Sixplace delegates routing and application state to the consuming app. The
/// feedback foundation uses only Flutter's own [ScaffoldMessenger], dialogs and
/// navigator APIs, so it works on Android, iOS, web, Windows, macOS and Linux.
abstract final class SPFeedback {
  /// Shows a short toast-like message using Flutter's [ScaffoldMessenger].
  ///
  /// This is intentionally framework-native rather than a platform toast, so
  /// behavior remains consistent across mobile, web and desktop.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showToast(
    BuildContext context,
    String message, {
    SPFeedbackType type = SPFeedbackType.info,
    Duration duration = const Duration(seconds: 2),
    bool clearExisting = true,
    SPFeedbackStyle style = const SPFeedbackStyle(),
  }) => showMessage(
    context,
    message,
    type: type,
    duration: duration,
    clearExisting: clearExisting,
    style: style,
  );

  /// Shows a transient message using the nearest [ScaffoldMessenger].
  ///
  /// Set [clearExisting] to false when messages should queue instead of
  /// replacing the currently visible snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMessage(
    BuildContext context,
    String message, {
    SPFeedbackType type = SPFeedbackType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool clearExisting = true,
    SPFeedbackStyle style = const SPFeedbackStyle(),
  }) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'Must be positive.');
    }
    if ((actionLabel == null) != (onAction == null)) {
      throw ArgumentError(
        'actionLabel and onAction must either both be supplied or both be null.',
      );
    }
    if (actionLabel != null && actionLabel.trim().isEmpty) {
      throw ArgumentError.value(
        actionLabel,
        'actionLabel',
        'Must not be empty.',
      );
    }
    if (style.behavior != SnackBarBehavior.floating &&
        (style.margin != null || style.width != null)) {
      throw ArgumentError(
        'SnackBar margin/width require SnackBarBehavior.floating.',
      );
    }
    if (style.width != null &&
        (!style.width!.isFinite || style.width! <= 0)) {
      throw ArgumentError.value(style.width, 'style.width', 'Must be positive.');
    }
    if (style.margin != null && style.width != null) {
      throw ArgumentError(
        'SnackBar margin and width cannot both be supplied.',
      );
    }
    if (style.elevation != null &&
        (!style.elevation!.isFinite || style.elevation! < 0)) {
      throw ArgumentError.value(
        style.elevation,
        'style.elevation',
        'Must be finite and non-negative.',
      );
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      throw StateError(
        'SPFeedback.showMessage requires a ScaffoldMessenger ancestor. '
        'Use it below MaterialApp/ScaffoldMessenger.',
      );
    }

    final theme = Theme.of(context);
    final colors = _colors(
      theme.colorScheme,
      type,
      theme.extension<SPThemeTokens>(),
    );
    if (clearExisting) messenger.clearSnackBars();

    return messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colors.foreground),
        ),
        backgroundColor: colors.background,
        duration: duration,
        behavior: style.behavior,
        showCloseIcon: style.showCloseIcon,
        closeIconColor: colors.foreground,
        margin: style.width == null ? style.margin : null,
        padding: style.padding,
        width: style.width,
        elevation: style.elevation,
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: colors.foreground,
                onPressed: onAction!,
              ),
      ),
    );
  }

  /// Shows a confirmation or informational alert dialog.
  ///
  /// Returns true after the confirm action, false after an explicit cancel
  /// action, and null when a dismissible dialog is dismissed externally.
  static Future<bool?> showAlert(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String? cancelLabel,
    SPFeedbackType type = SPFeedbackType.info,
    bool barrierDismissible = true,
    bool useRootNavigator = true,
  }) {
    if (confirmLabel.trim().isEmpty) {
      throw ArgumentError.value(
        confirmLabel,
        'confirmLabel',
        'Must not be empty.',
      );
    }
    if (cancelLabel != null && cancelLabel.trim().isEmpty) {
      throw ArgumentError.value(
        cancelLabel,
        'cancelLabel',
        'Must not be empty when supplied.',
      );
    }

    final theme = Theme.of(context);
    final colors = _colors(
      theme.colorScheme,
      type,
      theme.extension<SPThemeTokens>(),
    );
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(_iconFor(type), color: colors.background),
        title: Text(title),
        content: Text(message),
        actions: [
          if (cancelLabel != null)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Shows a blocking loading dialog and returns a route-specific handle.
  ///
  /// The returned handle should be closed from a `finally` block. By default,
  /// taps outside the loader and the system back action cannot dismiss it.
  static SPFeedbackLoaderHandle showLoading(
    BuildContext context, {
    String? message,
    Widget? progressIndicator,
    bool barrierDismissible = false,
    bool useRootNavigator = true,
  }) {
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => PopScope(
        canPop: barrierDismissible,
        child: SPBlockingLoader(
          message: message,
          progressIndicator: progressIndicator,
        ),
      ),
    );

    unawaited(navigator.push(route));
    return SPFeedbackLoaderHandle._(navigator, route);
  }

  static _FeedbackColors _colors(
    ColorScheme scheme,
    SPFeedbackType type,
    SPThemeTokens? tokens,
  ) => switch (type) {
    SPFeedbackType.info => _FeedbackColors(
      background: tokens?.info ?? scheme.primary,
      foreground: tokens?.onInfo ?? scheme.onPrimary,
    ),
    SPFeedbackType.success => _FeedbackColors(
      background:
          tokens?.success ??
          (scheme.brightness == Brightness.dark
              ? const Color(0xFF81C784)
              : const Color(0xFF2E7D32)),
      foreground:
          tokens?.onSuccess ??
          (scheme.brightness == Brightness.dark
              ? const Color(0xFF102312)
              : Colors.white),
    ),
    SPFeedbackType.warning => _FeedbackColors(
      background:
          tokens?.warning ??
          (scheme.brightness == Brightness.dark
              ? const Color(0xFFFFB74D)
              : const Color(0xFFED6C02)),
      foreground:
          tokens?.onWarning ??
          (scheme.brightness == Brightness.dark
              ? const Color(0xFF2B1700)
              : Colors.white),
    ),
    SPFeedbackType.error => _FeedbackColors(
      background: scheme.error,
      foreground: scheme.onError,
    ),
  };

  static IconData _iconFor(SPFeedbackType type) => switch (type) {
    SPFeedbackType.info => Icons.info_outline,
    SPFeedbackType.success => Icons.check_circle_outline,
    SPFeedbackType.warning => Icons.warning_amber_rounded,
    SPFeedbackType.error => Icons.error_outline,
  };
}

class _FeedbackColors {
  const _FeedbackColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
