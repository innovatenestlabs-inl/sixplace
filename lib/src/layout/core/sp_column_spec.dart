// src>layout>sp_column_spec.dart
import 'package:flutter/foundation.dart';

import 'sp_breakpoints.dart';
import 'sp_responsive_value.dart';

/// Describes how many of the twelve grid columns a widget occupies.
@immutable
class SPColumnSpec {
  const SPColumnSpec({
    this.span = columnCount,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
  }) : assert(span >= 1 && span <= columnCount, 'span must be from 1 to 12.'),
       assert(
         sm == null || (sm >= 1 && sm <= columnCount),
         'sm must be from 1 to 12.',
       ),
       assert(
         md == null || (md >= 1 && md <= columnCount),
         'md must be from 1 to 12.',
       ),
       assert(
         lg == null || (lg >= 1 && lg <= columnCount),
         'lg must be from 1 to 12.',
       ),
       assert(
         xl == null || (xl >= 1 && xl <= columnCount),
         'xl must be from 1 to 12.',
       ),
       assert(
         xxl == null || (xxl >= 1 && xxl <= columnCount),
         'xxl must be from 1 to 12.',
       );

  static const int columnCount = 12;

  /// Base span, active from the extra-small breakpoint.
  final int span;

  final int? sm;
  final int? md;
  final int? lg;
  final int? xl;
  final int? xxl;

  /// Returns the active column span for a parent width.
  int resolve(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return SPResponsiveValue<int>(
      base: span,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
      xxl: xxl,
    ).resolve(width, breakpoints: breakpoints);
  }

  /// Returns the active span as a fraction between 0 and 1.
  double widthFactor(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return resolve(width, breakpoints: breakpoints) / columnCount;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SPColumnSpec &&
            other.span == span &&
            other.sm == sm &&
            other.md == md &&
            other.lg == lg &&
            other.xl == xl &&
            other.xxl == xxl;
  }

  @override
  int get hashCode => Object.hash(span, sm, md, lg, xl, xxl);

  @override
  String toString() {
    return 'SPColumnSpec('
        'span: $span, '
        'sm: $sm, '
        'md: $md, '
        'lg: $lg, '
        'xl: $xl, '
        'xxl: $xxl'
        ')';
  }
}
