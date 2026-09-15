import 'package:flutter/material.dart';

import 'sixplace_core.dart';

/// Numeric width extension.
///
/// Example: `100.w` resolves to `100 * (logicalScreenWidth / designWidth)`.
extension SixPlaceNumWidth on num {
  double get w => SixPlace.metrics.widthOf(this);
}

/// Numeric height extension.
///
/// Example: `48.h` resolves to `48 * (logicalScreenHeight / designHeight)`.
extension SixPlaceNumHeight on num {
  double get h => SixPlace.metrics.heightOf(this);
}

/// Font-size extension following the design-scale + accessibility contract.
///
/// Formula: `n.sp = textScaler.scale(n * fontScale)`.
/// The accessibility scaling is applied exactly once at the final font size.
extension SixPlaceNumSp on num {
  double get sp => SixPlace.metrics.spOf(this);
}

/// Root-relative typography helper.
///
/// Formula: `n.rem = textScaler.scale(n * rootFontSize * fontScale)`.
extension SixPlaceNumRem on num {
  double get rem => SixPlace.metrics.remOf(this);
}

/// Parent-relative typography helper.
///
/// Use `1.5.em(context)` to resolve a value against the nearest inherited
/// `DefaultTextStyle.fontSize`.
extension SixPlaceNumEm on num {
  double em(BuildContext context, {double? fallbackFontSize}) =>
      SixPlace.metrics.emOf(this, context, fallbackFontSize: fallbackFontSize);
}

/// Convenience accessors for current metrics from a [BuildContext].
extension SixPlaceContext on BuildContext {
  SixPlaceMetrics metricsFromSixPlace() => SixPlaceMetrics.fromContext(
    this,
    designSize: SixPlace.metrics.designSize,
    rootFontSize: SixPlace.metrics.rootFontSize,
  );
}
