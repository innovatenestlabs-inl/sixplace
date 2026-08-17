import 'package:flutter/widgets.dart';

import '../core/sp_breakpoints.dart';

/// Controls the visibility of a widget based on the current screen width.
///
/// Uses [MediaQuery] to evaluate the viewport width, allowing it to be
/// safely placed anywhere in the widget tree, even within unbounded
/// scroll views.
class SPVisibility extends StatelessWidget {
  const SPVisibility({
    super.key,
    required this.child,
    this.replacement = const SizedBox.shrink(),
    this.hiddenXs = false,
    this.hiddenSm = false,
    this.hiddenMd = false,
    this.hiddenLg = false,
    this.hiddenXl = false,
    this.hiddenXxl = false,
    this.breakpoints = SPBreakpoints.standard,
  });

  /// The widget to display when visible.
  final Widget child;

  /// The widget to display when [child] is hidden. Defaults to [SizedBox.shrink].
  final Widget replacement;

  final bool hiddenXs;
  final bool hiddenSm;
  final bool hiddenMd;
  final bool hiddenLg;
  final bool hiddenXl;
  final bool hiddenXxl;

  final SPBreakpoints breakpoints;

  bool _isHidden(SPBreakpoint breakpoint) {
    switch (breakpoint) {
      case SPBreakpoint.xs:
        return hiddenXs;
      case SPBreakpoint.sm:
        return hiddenSm;
      case SPBreakpoint.md:
        return hiddenMd;
      case SPBreakpoint.lg:
        return hiddenLg;
      case SPBreakpoint.xl:
        return hiddenXl;
      case SPBreakpoint.xxl:
        return hiddenXxl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final activeBreakpoint = breakpoints.resolve(screenWidth);

    if (_isHidden(activeBreakpoint)) {
      return replacement;
    }

    return child;
  }
}
