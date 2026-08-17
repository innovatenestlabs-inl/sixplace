import 'package:flutter/foundation.dart';

import 'sp_breakpoints.dart';

/// Stores one value that can change across responsive breakpoints.
///
/// Missing values inherit from the nearest configured smaller breakpoint.
@immutable
class SPResponsiveValue<T> {
  const SPResponsiveValue({
    required this.base,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
  });

  /// Default value used from the extra-small breakpoint.
  final T base;

  final T? sm;
  final T? md;
  final T? lg;
  final T? xl;
  final T? xxl;

  /// Resolves the value using the supplied available width.
  T resolve(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return resolveBreakpoint(breakpoints.resolve(width));
  }

  /// Resolves the value using an already known breakpoint.
  T resolveBreakpoint(SPBreakpoint breakpoint) {
    var result = base;

    if (breakpoint.index >= SPBreakpoint.sm.index) {
      final value = sm;

      if (value != null) {
        result = value;
      }
    }

    if (breakpoint.index >= SPBreakpoint.md.index) {
      final value = md;

      if (value != null) {
        result = value;
      }
    }

    if (breakpoint.index >= SPBreakpoint.lg.index) {
      final value = lg;

      if (value != null) {
        result = value;
      }
    }

    if (breakpoint.index >= SPBreakpoint.xl.index) {
      final value = xl;

      if (value != null) {
        result = value;
      }
    }

    if (breakpoint.index >= SPBreakpoint.xxl.index) {
      final value = xxl;

      if (value != null) {
        result = value;
      }
    }

    return result;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SPResponsiveValue<T> &&
            other.base == base &&
            other.sm == sm &&
            other.md == md &&
            other.lg == lg &&
            other.xl == xl &&
            other.xxl == xxl;
  }

  @override
  int get hashCode => Object.hash(base, sm, md, lg, xl, xxl);

  @override
  String toString() {
    return 'SPResponsiveValue('
        'base: $base, '
        'sm: $sm, '
        'md: $md, '
        'lg: $lg, '
        'xl: $xl, '
        'xxl: $xxl'
        ')';
  }
}
