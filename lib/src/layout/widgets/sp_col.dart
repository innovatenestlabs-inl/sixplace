import 'package:flutter/widgets.dart';

import '../core/sp_breakpoints.dart';
import '../core/sp_column_spec.dart';

/// A responsive column intended to be placed inside an SPRow.
///
/// The base span defaults to 12. Therefore:
///
/// SPCol(md: 6)
///
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
    required this.child,
  }) : assert(
         span >= 1 && span <= SPColumnSpec.columnCount,
         'span must be from 1 to 12.',
       ),
       assert(
         sm == null || (sm >= 1 && sm <= SPColumnSpec.columnCount),
         'sm must be from 1 to 12.',
       ),
       assert(
         md == null || (md >= 1 && md <= SPColumnSpec.columnCount),
         'md must be from 1 to 12.',
       ),
       assert(
         lg == null || (lg >= 1 && lg <= SPColumnSpec.columnCount),
         'lg must be from 1 to 12.',
       ),
       assert(
         xl == null || (xl >= 1 && xl <= SPColumnSpec.columnCount),
         'xl must be from 1 to 12.',
       ),
       assert(
         xxl == null || (xxl >= 1 && xxl <= SPColumnSpec.columnCount),
         'xxl must be from 1 to 12.',
       );

  /// Base span beginning from the extra-small breakpoint.
  final int span;

  final int? sm;
  final int? md;
  final int? lg;
  final int? xl;
  final int? xxl;

  final Widget child;

  SPColumnSpec get specification {
    return SPColumnSpec(span: span, sm: sm, md: md, lg: lg, xl: xl, xxl: xxl);
  }

  int resolveSpan(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.bootstrap,
  }) {
    return specification.resolve(width, breakpoints: breakpoints);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
