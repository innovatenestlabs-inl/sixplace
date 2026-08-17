// src>widgets>sp_row.dart
import 'package:flutter/widgets.dart';

import '../core/sp_breakpoints.dart';
import '../core/sp_column_spec.dart';
import 'sp_col.dart';

/// Places responsive SPCol widgets inside a twelve-column wrapping row.
///
/// Responsive decisions use the immediate parent's available width instead
/// of the entire device screen width.
class SPRow extends StatelessWidget {
  const SPRow({
    super.key,
    required this.children,
    this.gap = 0,
    double? horizontalGap,
    double? verticalGap,
    this.breakpoints = SPBreakpoints.standard,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.clipBehavior = Clip.none,
  }) : horizontalGap = horizontalGap ?? gap,
       verticalGap = verticalGap ?? gap,
       assert(gap >= 0, 'gap cannot be negative.'),
       assert(
         horizontalGap == null || horizontalGap >= 0,
         'horizontalGap cannot be negative.',
       ),
       assert(
         verticalGap == null || verticalGap >= 0,
         'verticalGap cannot be negative.',
       );

  final List<SPCol> children;

  /// Shorthand value for horizontal and vertical gaps.
  final double gap;

  /// Space between visible column contents.
  final double horizontalGap;

  /// Space between wrapped rows.
  final double verticalGap;

  final SPBreakpoints breakpoints;

  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final WrapCrossAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final Clip clipBehavior;

  static const double _precisionTolerance = 0.0001;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError(
            'SPRow requires a bounded width. Place it inside a widget '
            'that provides a finite width, such as SizedBox, Expanded, '
            'Padding, SPContainer, or a normal screen body.',
          );
        }

        final availableWidth = constraints.maxWidth;
        final halfHorizontalGap = horizontalGap / 2;

        final resolvedChildren = children
            .map((SPCol column) {
              final span = column.resolveSpan(
                availableWidth,
                breakpoints: breakpoints,
              );

              final calculatedWidth =
                  availableWidth * span / SPColumnSpec.columnCount;

              /*
             * Prevent tiny floating-point excesses such as:
             *
             * 8 / 12 + 4 / 12 = 12.0000000001
             *
             * from producing an unexpected extra row.
             */
              final columnWidth =
                  span == SPColumnSpec.columnCount ||
                      calculatedWidth <= _precisionTolerance
                  ? calculatedWidth
                  : calculatedWidth - _precisionTolerance;

              return SizedBox(
                width: columnWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: halfHorizontalGap),
                  child: column,
                ),
              );
            })
            .toList(growable: false);

        return SizedBox(
          width: availableWidth,
          child: Wrap(
            alignment: alignment,
            runAlignment: runAlignment,
            runSpacing: verticalGap,
            crossAxisAlignment: crossAxisAlignment,
            textDirection: textDirection,
            verticalDirection: verticalDirection,
            clipBehavior: clipBehavior,
            children: resolvedChildren,
          ),
        );
      },
    );
  }
}
