import 'package:flutter/foundation.dart';

/// The six responsive tiers supported by Sixplace.
enum SPBreakpoint { xs, sm, md, lg, xl, xxl }

/// Defines the minimum widths at which responsive tiers become active.
@immutable
class SPBreakpoints {
  /// Defaults match Bootstrap 5 breakpoints.
  const SPBreakpoints({
    this.sm = 576,
    this.md = 768,
    this.lg = 992,
    this.xl = 1200,
    this.xxl = 1400,
  }) : assert(sm > 0, 'sm must be greater than zero.'),
       assert(md > sm, 'md must be greater than sm.'),
       assert(lg > md, 'lg must be greater than md.'),
       assert(xl > lg, 'xl must be greater than lg.'),
       assert(xxl > xl, 'xxl must be greater than xl.');

  static const SPBreakpoints bootstrap = SPBreakpoints();

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  /// Returns the active breakpoint for an available width.
  SPBreakpoint resolve(double width) {
    if (width.isNaN || width < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'Width must be a non-negative number.',
      );
    }

    if (width >= xxl) {
      return SPBreakpoint.xxl;
    }

    if (width >= xl) {
      return SPBreakpoint.xl;
    }

    if (width >= lg) {
      return SPBreakpoint.lg;
    }

    if (width >= md) {
      return SPBreakpoint.md;
    }

    if (width >= sm) {
      return SPBreakpoint.sm;
    }

    return SPBreakpoint.xs;
  }

  /// Returns the minimum width belonging to a breakpoint.
  double minimumWidthOf(SPBreakpoint breakpoint) {
    switch (breakpoint) {
      case SPBreakpoint.xs:
        return 0;
      case SPBreakpoint.sm:
        return sm;
      case SPBreakpoint.md:
        return md;
      case SPBreakpoint.lg:
        return lg;
      case SPBreakpoint.xl:
        return xl;
      case SPBreakpoint.xxl:
        return xxl;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SPBreakpoints &&
            other.sm == sm &&
            other.md == md &&
            other.lg == lg &&
            other.xl == xl &&
            other.xxl == xxl;
  }

  @override
  int get hashCode => Object.hash(sm, md, lg, xl, xxl);

  @override
  String toString() {
    return 'SPBreakpoints('
        'sm: $sm, '
        'md: $md, '
        'lg: $lg, '
        'xl: $xl, '
        'xxl: $xxl'
        ')';
  }
}
