import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/sp_breakpoints.dart';

/// A highly flexible, responsive wrapper around Flutter's native [Scaffold].
///
/// Passes through all native [Scaffold] behaviors, allowing it to be used
/// exactly like a standard [Scaffold]. However, it introduces intelligent
/// responsive layout capabilities:
///
/// By providing specific breakpoints, developers can automatically transform
/// a fly-out [drawer] into a permanent side navigation panel on desktop screens,
/// display a [navigationRail] on tablet screens, and hide the
/// [bottomNavigationBar] on larger screens—all without writing complex
/// [MediaQuery] checks or duplicating widget trees.
class SPScaffold extends StatelessWidget {
  const SPScaffold({
    super.key,
    this.scaffoldKey,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
    this.breakpoints = SPBreakpoints.standard,
    this.permanentDrawerBreakpoint,
    this.permanentEndDrawerBreakpoint,
    this.navigationRail,
    this.navigationRailBreakpoint,
    this.hideBottomNavBreakpoint,
  });

  // --- Responsive Navigation Properties --- //

  /// The global breakpoint definitions used to evaluate screen width.
  final SPBreakpoints breakpoints;

  /// The minimum breakpoint at which the [drawer] becomes permanently visible
  /// alongside the body (like a desktop sidebar) rather than hidden behind a menu.
  /// Defaults to null (always utilizes native fly-out drawer behavior).
  final SPBreakpoint? permanentDrawerBreakpoint;

  /// The minimum breakpoint at which the [endDrawer] becomes permanently visible
  /// alongside the body on the right side.
  /// Defaults to null (always utilizes native right fly-out drawer behavior).
  final SPBreakpoint? permanentEndDrawerBreakpoint;

  /// A widget to display as a navigation rail (a thin vertical navigation bar).
  /// Usually used on medium tablet screens.
  final Widget? navigationRail;

  /// The minimum breakpoint at which the [navigationRail] is shown.
  /// If the screen reaches the [permanentDrawerBreakpoint], the rail is hidden
  /// in favor of the full drawer.
  /// Defaults to null.
  final SPBreakpoint? navigationRailBreakpoint;

  /// The minimum breakpoint at which the [bottomNavigationBar] is automatically hidden.
  /// Usually set to [SPBreakpoint.md] so bottom navs only appear on phones.
  /// Defaults to null (never automatically hidden).
  final SPBreakpoint? hideBottomNavBreakpoint;

  // --- Standard Scaffold Properties --- //

  final Key? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final AlignmentDirectional persistentFooterAlignment;
  final Widget? drawer;
  final DrawerCallback? onDrawerChanged;
  final Widget? endDrawer;
  final DrawerCallback? onEndDrawerChanged;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final activeBreakpoint = breakpoints.resolve(screenWidth);

    // Evaluate visibility logic based on breakpoints
    final showPermanentDrawer =
        permanentDrawerBreakpoint != null &&
        activeBreakpoint.index >= permanentDrawerBreakpoint!.index &&
        drawer != null;

    final showPermanentEndDrawer =
        permanentEndDrawerBreakpoint != null &&
        activeBreakpoint.index >= permanentEndDrawerBreakpoint!.index &&
        endDrawer != null;

    final showNavRail =
        navigationRailBreakpoint != null &&
        activeBreakpoint.index >= navigationRailBreakpoint!.index &&
        navigationRail != null &&
        !showPermanentDrawer;

    final hideBottomNav =
        hideBottomNavBreakpoint != null &&
        activeBreakpoint.index >= hideBottomNavBreakpoint!.index &&
        bottomNavigationBar != null;

    Widget? resolvedBody = body;

    // Inject Sidebars alongside the body if responsive conditions are met
    if (showPermanentDrawer || showNavRail || showPermanentEndDrawer) {
      resolvedBody = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPermanentDrawer)
            drawer!
          else if (showNavRail)
            navigationRail!,

          Expanded(child: body ?? const SizedBox.shrink()),

          if (showPermanentEndDrawer) endDrawer!,
        ],
      );
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      body: resolvedBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      persistentFooterAlignment: persistentFooterAlignment,
      // If rendering permanently, hide the native drawers
      drawer: showPermanentDrawer ? null : drawer,
      onDrawerChanged: onDrawerChanged,
      endDrawer: showPermanentEndDrawer ? null : endDrawer,
      onEndDrawerChanged: onEndDrawerChanged,
      bottomNavigationBar: hideBottomNav ? null : bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }
}
