// lib/src/layout/widgets/sp_row.dart

import 'package:flutter/widgets.dart';

import '../core/sp_breakpoints.dart';
import '../core/sp_column_spec.dart';
import '../core/sp_responsive_value.dart';
import 'sp_col.dart';

/// Places responsive [SPCol] widgets inside a twelve-column wrapping row.
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
    this.responsiveGap,
    this.breakpoints = SPBreakpoints.standard,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.clipBehavior = Clip.none,
  }) : horizontalGap = horizontalGap ?? gap,
       verticalGap = verticalGap ?? gap,
       _horizontalGapUsesGeneralGap = horizontalGap == null,
       _verticalGapUsesGeneralGap = verticalGap == null,
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

  /// Static shorthand value for horizontal and vertical gaps.
  ///
  /// This remains fully backward-compatible with the original API.
  final double gap;

  /// Static horizontal space between visible column contents.
  ///
  /// When omitted, [gap] or [responsiveGap] supplies the horizontal gap.
  final double horizontalGap;

  /// Static vertical space between wrapped rows.
  ///
  /// When omitted, [gap] or [responsiveGap] supplies the vertical gap.
  final double verticalGap;

  /// Optional responsive shorthand for horizontal and vertical gaps.
  ///
  /// This resolves from the immediate parent's available width.
  ///
  /// Explicit [horizontalGap] or [verticalGap] values override this value
  /// for their respective axis.
  ///
  /// Example:
  ///
  /// ```dart
  /// SPRow(
  ///   responsiveGap: const SPResponsiveValue<double>(
  ///     base: 8,
  ///     md: 12,
  ///     lg: 16,
  ///   ),
  ///   children: columns,
  /// )
  /// ```
  final SPResponsiveValue<double>? responsiveGap;

  final bool _horizontalGapUsesGeneralGap;
  final bool _verticalGapUsesGeneralGap;

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

        final resolvedGeneralGap =
            responsiveGap?.resolve(availableWidth, breakpoints: breakpoints) ??
            gap;

        final resolvedHorizontalGap = _horizontalGapUsesGeneralGap
            ? resolvedGeneralGap
            : horizontalGap;

        final resolvedVerticalGap = _verticalGapUsesGeneralGap
            ? resolvedGeneralGap
            : verticalGap;

        _validateResolvedGap(resolvedHorizontalGap, 'horizontal gap');

        _validateResolvedGap(resolvedVerticalGap, 'vertical gap');

        final halfHorizontalGap = resolvedHorizontalGap / 2;

        // Sort children by their active responsive order.
        final sortedChildren = List<SPCol>.of(children)
          ..sort((a, b) {
            final orderA = a.resolveOrder(
              availableWidth,
              breakpoints: breakpoints,
            );

            final orderB = b.resolveOrder(
              availableWidth,
              breakpoints: breakpoints,
            );

            return orderA.compareTo(orderB);
          });

        final resolvedChildren = sortedChildren
            .map((SPCol column) {
              final span = column.resolveSpan(
                availableWidth,
                breakpoints: breakpoints,
              );

              final offset = column.resolveOffset(
                availableWidth,
                breakpoints: breakpoints,
              );

              final calculatedWidth =
                  availableWidth * span / SPColumnSpec.columnCount;

              final calculatedOffsetWidth =
                  availableWidth * offset / SPColumnSpec.columnCount;

              /*
               * Prevent tiny floating-point excesses such as:
               * 8 / 12 + 4 / 12 = 12.0000000001
               * from producing an unexpected extra row.
               */
              final columnWidth =
                  span == SPColumnSpec.columnCount ||
                      calculatedWidth <= _precisionTolerance
                  ? calculatedWidth
                  : calculatedWidth - _precisionTolerance;

              Widget childWidget = SizedBox(
                width: columnWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: halfHorizontalGap),
                  child: column,
                ),
              );

              if (offset > 0) {
                childWidget = Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: calculatedOffsetWidth,
                  ),
                  child: childWidget,
                );
              }

              return childWidget;
            })
            .toList(growable: false);

        return SizedBox(
          width: availableWidth,
          child: Wrap(
            alignment: alignment,
            runAlignment: runAlignment,
            runSpacing: resolvedVerticalGap,
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

  static void _validateResolvedGap(double value, String propertyName) {
    if (!value.isFinite || value < 0) {
      throw FlutterError(
        'SPRow resolved $propertyName to $value. '
        'Responsive gap values must be finite and non-negative.',
      );
    }
  }
}
