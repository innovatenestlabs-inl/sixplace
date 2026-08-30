import 'package:flutter/widgets.dart';

import 'sp_breakpoints.dart';
import 'sp_responsive_value.dart';

/// Provides convenient access to viewport-responsive information.
///
/// Use [SPResponsive.of] or the `context.sp` extension:
///
/// ```dart
/// final responsive = context.sp;
///
/// if (responsive.isDesktop) {
///   // Execute desktop-specific non-layout behavior.
/// }
/// ```
///
/// Layout differences should generally be implemented with [SPRow], [SPCol],
/// [SPVisibility], and other responsive widgets instead of conditionally
/// constructing completely separate page trees.
@immutable
class SPResponsive {
  const SPResponsive._({
    required this.size,
    required this.breakpoints,
    required this.breakpoint,
  });

  /// Creates responsive information from an explicit viewport size.
  ///
  /// This is especially useful for tests and non-widget calculations.
  factory SPResponsive.fromSize(
    Size size, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return SPResponsive._(
      size: size,
      breakpoints: breakpoints,
      breakpoint: breakpoints.resolve(size.width),
    );
  }

  /// Creates responsive information from the current [MediaQuery].
  ///
  /// This method listens only to MediaQuery size changes through
  /// [MediaQuery.sizeOf].
  factory SPResponsive.of(
    BuildContext context, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return SPResponsive.fromSize(
      MediaQuery.sizeOf(context),
      breakpoints: breakpoints,
    );
  }

  /// Current viewport size.
  final Size size;

  /// Breakpoint configuration used to resolve [breakpoint].
  final SPBreakpoints breakpoints;

  /// Currently active breakpoint.
  final SPBreakpoint breakpoint;

  /// Current viewport width.
  double get width => size.width;

  /// Current viewport height.
  double get height => size.height;

  bool get isXs => breakpoint == SPBreakpoint.xs;
  bool get isSm => breakpoint == SPBreakpoint.sm;
  bool get isMd => breakpoint == SPBreakpoint.md;
  bool get isLg => breakpoint == SPBreakpoint.lg;
  bool get isXl => breakpoint == SPBreakpoint.xl;
  bool get isXxl => breakpoint == SPBreakpoint.xxl;

  /// True for xs and sm viewports.
  ///
  /// The default mobile range is below 768 logical pixels.
  bool get isMobile => breakpoint.index < SPBreakpoint.md.index;

  /// True for the md viewport.
  ///
  /// The default tablet range is 768–991.99 logical pixels.
  bool get isTablet => breakpoint == SPBreakpoint.md;

  /// True from the lg breakpoint upward.
  ///
  /// This includes large desktop viewports.
  bool get isDesktop => breakpoint.index >= SPBreakpoint.lg.index;

  /// True from the xxl breakpoint upward.
  ///
  /// With standard breakpoints, this begins at 1400 logical pixels.
  bool get isLargeDesktop => breakpoint.index >= SPBreakpoint.xxl.index;

  /// Returns true when the active breakpoint is at least [minimum].
  bool atLeast(SPBreakpoint minimum) {
    return breakpoint.index >= minimum.index;
  }

  /// Returns true when the active breakpoint is below [minimum].
  bool below(SPBreakpoint minimum) {
    return breakpoint.index < minimum.index;
  }

  /// Resolves a responsive value using the already-known breakpoint.
  T resolve<T>(SPResponsiveValue<T> value) {
    return value.resolveBreakpoint(breakpoint);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SPResponsive &&
            other.size == size &&
            other.breakpoints == breakpoints &&
            other.breakpoint == breakpoint;
  }

  @override
  int get hashCode => Object.hash(size, breakpoints, breakpoint);

  @override
  String toString() {
    return 'SPResponsive('
        'size: $size, '
        'breakpoint: $breakpoint, '
        'breakpoints: $breakpoints'
        ')';
  }
}

/// Convenient viewport-responsive access through `context.sp`.
extension SPResponsiveBuildContext on BuildContext {
  /// Returns responsive information using standard Sixplace breakpoints.
  SPResponsive get sp => SPResponsive.of(this);
}

/// Allows an [SPResponsiveValue] to resolve itself from a [BuildContext].
extension SPResponsiveValueBuildContext<T> on SPResponsiveValue<T> {
  /// Resolves this value using the current viewport width.
  ///
  /// Example:
  ///
  /// ```dart
  /// final height = const SPResponsiveValue<double?>(
  ///   base: null,
  ///   lg: 350,
  /// ).resolveFrom(context);
  /// ```
  T resolveFrom(
    BuildContext context, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return SPResponsive.of(context, breakpoints: breakpoints).resolve(this);
  }
}
