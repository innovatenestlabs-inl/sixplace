import 'package:flutter/widgets.dart';

import '../core/sp_breakpoints.dart';
import '../core/sp_responsive.dart';
import '../core/sp_responsive_value.dart';

/// A [SizedBox] whose width and height can change by viewport breakpoint.
///
/// Values are automatically resolved using the current viewport width.
/// Application code does not need to read [MediaQuery] or manually call
/// [SPResponsiveValue.resolve].
///
/// Example:
///
/// ```dart
/// SPResponsiveSizedBox(
///   height: const SPResponsiveValue<double?>(
///     base: null,
///     lg: 350,
///   ),
///   child: chart,
/// )
/// ```
///
/// A resolved null width or height behaves exactly like a null width or height
/// on Flutter's native [SizedBox].
class SPResponsiveSizedBox extends StatelessWidget {
  const SPResponsiveSizedBox({
    super.key,
    this.width,
    this.height,
    this.breakpoints = SPBreakpoints.standard,
    this.child,
  });

  /// Responsive width.
  ///
  /// When null, no explicit width is applied.
  final SPResponsiveValue<double?>? width;

  /// Responsive height.
  ///
  /// When null, no explicit height is applied.
  final SPResponsiveValue<double?>? height;

  /// Breakpoints used to resolve [width] and [height].
  final SPBreakpoints breakpoints;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final responsive = SPResponsive.of(context, breakpoints: breakpoints);

    final resolvedWidth = width == null ? null : responsive.resolve(width!);

    final resolvedHeight = height == null ? null : responsive.resolve(height!);

    return SizedBox(width: resolvedWidth, height: resolvedHeight, child: child);
  }
}
