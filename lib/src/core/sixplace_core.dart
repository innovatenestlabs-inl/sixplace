import 'package:flutter/material.dart';

/// Shared metrics used by the numeric sizing helpers.
///
/// Sixplace keeps these values in a single, view-scoped configuration so that
/// `num.w`, `num.h`, `num.sp`, and `num.rem` can resolve consistently without
/// storing a [BuildContext] or capturing a widget tree.
///
/// Initialize from a live [MediaQuery] using [SixPlace.init] or a
/// [SixPlaceScope]. The values are recalculated when the viewport size,
/// device pixel ratio, or system text scaling changes.
class SixPlace {
  static SixPlaceMetrics _metrics = const SixPlaceMetrics.uninitialized();

  static bool get isInitialized => _metrics.isInitialized;

  static SixPlaceMetrics get metrics {
    if (!isInitialized) {
      throw StateError(
        'SixPlace is not initialized. Call SixPlace.init(context, ...) before using .w, .h, .sp, .rem, or .em(context).',
      );
    }
    return _metrics;
  }

  static void init(
    BuildContext context, {
    Size designSize = const Size(390, 844),
    double rootFontSize = 16.0,
  }) {
    _metrics = SixPlaceMetrics.fromContext(
      context,
      designSize: designSize,
      rootFontSize: rootFontSize,
    );
  }

  static void reset() {
    _metrics = const SixPlaceMetrics.uninitialized();
  }
}

/// Immutable sizing and typography metrics resolved from the active UI.
@immutable
class SixPlaceMetrics {
  const SixPlaceMetrics._({
    required this.designSize,
    required this.rootFontSize,
    required this.logicalScreenSize,
    required this.devicePixelRatio,
    required this.textScaler,
  });

  const SixPlaceMetrics.uninitialized()
    : designSize = const Size(390, 844),
      rootFontSize = 16.0,
      logicalScreenSize = Size.zero,
      devicePixelRatio = 1.0,
      textScaler = TextScaler.noScaling;

  final Size designSize;
  final double rootFontSize;
  final Size logicalScreenSize;
  final double devicePixelRatio;
  final TextScaler textScaler;

  bool get isInitialized =>
      designSize.width > 0 &&
      designSize.height > 0 &&
      rootFontSize > 0 &&
      logicalScreenSize.width > 0 &&
      logicalScreenSize.height > 0;

  factory SixPlaceMetrics.fromContext(
    BuildContext context, {
    Size designSize = const Size(390, 844),
    double rootFontSize = 16.0,
  }) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      throw StateError(
        'SixPlace.init(context, ...) requires a MediaQuery ancestor. Wrap the app in a MaterialApp or MediaQuery before initializing.',
      );
    }

    final validatedDesignSize = _validateDesignSize(designSize);
    final validatedRootFontSize = _validateRootFontSize(rootFontSize);

    return SixPlaceMetrics._(
      designSize: validatedDesignSize,
      rootFontSize: validatedRootFontSize,
      logicalScreenSize: mediaQuery.size,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      textScaler: mediaQuery.textScaler,
    );
  }

  static Size _validateDesignSize(Size value) {
    if (!value.width.isFinite || !value.height.isFinite) {
      throw ArgumentError.value(
        value,
        'designSize',
        'Design size must contain finite values.',
      );
    }
    if (value.width <= 0 || value.height <= 0) {
      throw ArgumentError.value(
        value,
        'designSize',
        'Design size must be greater than zero in both dimensions.',
      );
    }
    return value;
  }

  static double _validateRootFontSize(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        'rootFontSize',
        'Root font size must be finite.',
      );
    }
    if (value <= 0) {
      throw ArgumentError.value(
        value,
        'rootFontSize',
        'Root font size must be greater than zero.',
      );
    }
    return value;
  }

  double get widthScale =>
      _requireInitialized(logicalScreenSize.width / designSize.width);

  double get heightScale =>
      _requireInitialized(logicalScreenSize.height / designSize.height);

  double get fontScale => widthScale;

  double _requireInitialized(double value) {
    if (!isInitialized) {
      throw StateError(
        'SixPlace metrics are not initialized. Call SixPlace.init(context, ...) before resolving sizing or typography values.',
      );
    }
    return value;
  }

  double widthOf(num value) =>
      _requireInitialized(value.toDouble() * widthScale);

  double heightOf(num value) =>
      _requireInitialized(value.toDouble() * heightScale);

  double spOf(num value) =>
      _requireInitialized(textScaler.scale(value.toDouble() * fontScale));

  double remOf(num value) => _requireInitialized(
    textScaler.scale(value.toDouble() * rootFontSize * fontScale),
  );

  double emOf(num value, BuildContext context, {double? fallbackFontSize}) {
    final inherited = DefaultTextStyle.of(context).style.fontSize;
    final parentSize = inherited ?? fallbackFontSize ?? rootFontSize;
    if (!parentSize.isFinite || parentSize <= 0) {
      return _requireInitialized(
        textScaler.scale(value.toDouble() * rootFontSize),
      );
    }
    return _requireInitialized(textScaler.scale(value.toDouble() * parentSize));
  }
}

/// A widget that initializes the shared metrics for its subtree.
class SixPlaceScope extends StatelessWidget {
  const SixPlaceScope({
    super.key,
    this.designSize = const Size(390, 844),
    this.rootFontSize = 16.0,
    required this.child,
  });

  final Size designSize;
  final double rootFontSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    SixPlace.init(context, designSize: designSize, rootFontSize: rootFontSize);
    return child;
  }
}
