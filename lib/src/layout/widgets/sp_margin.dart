import 'package:flutter/widgets.dart';

import '../core/sp_breakpoints.dart';
import '../core/sp_responsive_value.dart';

/// Applies responsive margin around a widget based on the current screen width.
///
/// Uses [MediaQuery] to evaluate the viewport width, allowing it to be
/// safely placed anywhere in the widget tree.
class SPMargin extends StatelessWidget {
  const SPMargin({
    super.key,
    required this.base,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
    this.breakpoints = SPBreakpoints.standard,
    required this.child,
  });

  /// The default margin applied from the extra-small breakpoint.
  final EdgeInsetsGeometry base;

  final EdgeInsetsGeometry? sm;
  final EdgeInsetsGeometry? md;
  final EdgeInsetsGeometry? lg;
  final EdgeInsetsGeometry? xl;
  final EdgeInsetsGeometry? xxl;

  final SPBreakpoints breakpoints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final resolvedMargin = SPResponsiveValue<EdgeInsetsGeometry>(
      base: base,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
      xxl: xxl,
    ).resolve(screenWidth, breakpoints: breakpoints);

    return Padding(padding: resolvedMargin, child: child);
  }
}
