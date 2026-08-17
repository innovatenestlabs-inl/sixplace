import 'package:flutter/foundation.dart';

import 'sp_breakpoints.dart';
import 'sp_responsive_value.dart';

/// Describes how many of the twelve grid columns a widget occupies,
/// as well as its offset and visual order.
@immutable
class SPColumnSpec {
  const SPColumnSpec({
    this.span = columnCount,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
    this.offset = 0,
    this.offsetSm,
    this.offsetMd,
    this.offsetLg,
    this.offsetXl,
    this.offsetXxl,
    this.order = 0,
    this.orderSm,
    this.orderMd,
    this.orderLg,
    this.orderXl,
    this.orderXxl,
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
       ),
       assert(
         offset >= 0 && offset < columnCount,
         'offset must be from 0 to 11.',
       ),
       assert(
         offsetSm == null || (offsetSm >= 0 && offsetSm < columnCount),
         'offsetSm must be from 0 to 11.',
       ),
       assert(
         offsetMd == null || (offsetMd >= 0 && offsetMd < columnCount),
         'offsetMd must be from 0 to 11.',
       ),
       assert(
         offsetLg == null || (offsetLg >= 0 && offsetLg < columnCount),
         'offsetLg must be from 0 to 11.',
       ),
       assert(
         offsetXl == null || (offsetXl >= 0 && offsetXl < columnCount),
         'offsetXl must be from 0 to 11.',
       ),
       assert(
         offsetXxl == null || (offsetXxl >= 0 && offsetXxl < columnCount),
         'offsetXxl must be from 0 to 11.',
       );

  static const int columnCount = 12;

  /// Base span active from the extra-small breakpoint.
  final int span;
  final int? sm, md, lg, xl, xxl;

  /// Base offset (empty columns before this column) active from the extra-small breakpoint.
  final int offset;
  final int? offsetSm, offsetMd, offsetLg, offsetXl, offsetXxl;

  /// Base order (visual sorting) active from the extra-small breakpoint.
  final int order;
  final int? orderSm, orderMd, orderLg, orderXl, orderXxl;

  /// Returns the active column span for a parent width.
  int resolveSpan(
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

  /// Returns the active column offset for a parent width.
  int resolveOffset(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return SPResponsiveValue<int>(
      base: offset,
      sm: offsetSm,
      md: offsetMd,
      lg: offsetLg,
      xl: offsetXl,
      xxl: offsetXxl,
    ).resolve(width, breakpoints: breakpoints);
  }

  /// Returns the active visual order for a parent width.
  int resolveOrder(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return SPResponsiveValue<int>(
      base: order,
      sm: orderSm,
      md: orderMd,
      lg: orderLg,
      xl: orderXl,
      xxl: orderXxl,
    ).resolve(width, breakpoints: breakpoints);
  }

  /// Returns the active span as a fraction between 0 and 1.
  double widthFactor(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return resolveSpan(width, breakpoints: breakpoints) / columnCount;
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
            other.xxl == xxl &&
            other.offset == offset &&
            other.offsetSm == offsetSm &&
            other.offsetMd == offsetMd &&
            other.offsetLg == offsetLg &&
            other.offsetXl == offsetXl &&
            other.offsetXxl == offsetXxl &&
            other.order == order &&
            other.orderSm == orderSm &&
            other.orderMd == orderMd &&
            other.orderLg == orderLg &&
            other.orderXl == orderXl &&
            other.orderXxl == orderXxl;
  }

  @override
  int get hashCode => Object.hashAll([
    span,
    sm,
    md,
    lg,
    xl,
    xxl,
    offset,
    offsetSm,
    offsetMd,
    offsetLg,
    offsetXl,
    offsetXxl,
    order,
    orderSm,
    orderMd,
    orderLg,
    orderXl,
    orderXxl,
  ]);
}
