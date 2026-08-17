import 'package:flutter/widgets.dart';

import '../core/sp_breakpoints.dart';
import '../core/sp_column_spec.dart';

/// A responsive column intended to be placed inside an SPRow.
///
/// The base span defaults to 12. Therefore:
/// `SPCol(md: 6, child: ...)`
/// is full-width on smaller layouts and half-width from md upward.
class SPCol extends StatelessWidget {
  const SPCol({
    super.key,
    this.span = SPColumnSpec.columnCount,
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
    required this.child,
  });

  /// Base span beginning from the extra-small breakpoint.
  final int span;
  final int? sm, md, lg, xl, xxl;

  /// Base offset (empty space before the column) beginning from the extra-small breakpoint.
  final int offset;
  final int? offsetSm, offsetMd, offsetLg, offsetXl, offsetXxl;

  /// Base visual order beginning from the extra-small breakpoint.
  final int order;
  final int? orderSm, orderMd, orderLg, orderXl, orderXxl;

  final Widget child;

  /// Returns the configured SPColumnSpec for this column.
  SPColumnSpec get specification {
    return SPColumnSpec(
      span: span,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
      xxl: xxl,
      offset: offset,
      offsetSm: offsetSm,
      offsetMd: offsetMd,
      offsetLg: offsetLg,
      offsetXl: offsetXl,
      offsetXxl: offsetXxl,
      order: order,
      orderSm: orderSm,
      orderMd: orderMd,
      orderLg: orderLg,
      orderXl: orderXl,
      orderXxl: orderXxl,
    );
  }

  int resolveSpan(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return specification.resolveSpan(width, breakpoints: breakpoints);
  }

  int resolveOffset(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return specification.resolveOffset(width, breakpoints: breakpoints);
  }

  int resolveOrder(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    return specification.resolveOrder(width, breakpoints: breakpoints);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
