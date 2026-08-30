// lib/src/layout/widgets/sp_container.dart

import 'package:flutter/widgets.dart';

import '../core/sp_breakpoints.dart';
import '../core/sp_responsive_value.dart';

/// Maximum widths used by a fixed [SPContainer].
@immutable
class SPContainerWidths {
  /// Defaults match Bootstrap 5 container widths.
  const SPContainerWidths({
    this.sm = 540,
    this.md = 720,
    this.lg = 960,
    this.xl = 1140,
    this.xxl = 1320,
  }) : assert(sm > 0, 'sm must be greater than zero.'),
       assert(md > sm, 'md must be greater than sm.'),
       assert(lg > md, 'lg must be greater than md.'),
       assert(xl > lg, 'xl must be greater than lg.'),
       assert(xxl > xl, 'xxl must be greater than xl.');

  static const SPContainerWidths bootstrap = SPContainerWidths();

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  /// Resolves the maximum container width for the available parent width.
  double resolve(
    double width, {
    SPBreakpoints breakpoints = SPBreakpoints.standard,
  }) {
    final breakpoint = breakpoints.resolve(width);

    switch (breakpoint) {
      case SPBreakpoint.xs:
        return width;
      case SPBreakpoint.sm:
        return sm > width ? width : sm;
      case SPBreakpoint.md:
        return md > width ? width : md;
      case SPBreakpoint.lg:
        return lg > width ? width : lg;
      case SPBreakpoint.xl:
        return xl > width ? width : xl;
      case SPBreakpoint.xxl:
        return xxl > width ? width : xxl;
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SPContainerWidths &&
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
    return 'SPContainerWidths('
        'sm: $sm, '
        'md: $md, '
        'lg: $lg, '
        'xl: $xl, '
        'xxl: $xxl'
        ')';
  }
}

/// Centers content inside a fixed-width or fluid responsive container.
///
/// Responsive decisions use the immediate parent's available width.
class SPContainer extends StatelessWidget {
  const SPContainer({
    super.key,
    required this.child,
    this.fluid = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.responsivePadding,
    this.alignment = Alignment.topCenter,
    this.breakpoints = SPBreakpoints.standard,
    this.widths = SPContainerWidths.bootstrap,
  });

  const SPContainer.fluid({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.responsivePadding,
    this.alignment = Alignment.topCenter,
    this.breakpoints = SPBreakpoints.standard,
    this.widths = SPContainerWidths.bootstrap,
  }) : fluid = true;

  final Widget child;

  /// When true, the container uses all available width.
  final bool fluid;

  /// Static padding used when [responsivePadding] is null.
  final EdgeInsetsGeometry padding;

  /// Optional responsive padding.
  ///
  /// When provided, this takes precedence over [padding] and resolves using
  /// the immediate parent's available width.
  ///
  /// Example:
  ///
  /// ```dart
  /// SPContainer.fluid(
  ///   responsivePadding:
  ///       const SPResponsiveValue<EdgeInsetsGeometry>(
  ///     base: EdgeInsets.all(8),
  ///     lg: EdgeInsets.all(16),
  ///   ),
  ///   child: content,
  /// )
  /// ```
  final SPResponsiveValue<EdgeInsetsGeometry>? responsivePadding;

  final AlignmentGeometry alignment;
  final SPBreakpoints breakpoints;
  final SPContainerWidths widths;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError(
            'SPContainer requires a bounded width. '
            'Place it inside a widget that provides a finite width.',
          );
        }

        final availableWidth = constraints.maxWidth;

        final containerWidth = fluid
            ? availableWidth
            : widths.resolve(availableWidth, breakpoints: breakpoints);

        final resolvedPadding =
            responsivePadding?.resolve(
              availableWidth,
              breakpoints: breakpoints,
            ) ??
            padding;

        return Align(
          alignment: alignment,
          child: SizedBox(
            width: containerWidth,
            child: Padding(padding: resolvedPadding, child: child),
          ),
        );
      },
    );
  }
}
