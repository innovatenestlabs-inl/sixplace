// src>widgets>sp_app_bar.dart

import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A platform-adaptive Sixplace application bar.
///
/// Android, web and desktop use Material styling.
/// iOS automatically receives iOS navigation-bar styling.
class SPAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _iosToolbarHeight = 44;

  final String title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;

  final bool automaticallyImplyLeading;
  final bool showDrawerIcon;
  final VoidCallback? onDrawerPressed;

  /// When null:
  /// - iOS: centered
  /// - Other platforms: left aligned
  final bool? centerTitle;

  final PreferredSizeWidget? bottom;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? shadowColor;
  final Color? surfaceTintColor;

  final TextStyle? titleTextStyle;
  final ShapeBorder? shape;

  /// When null:
  /// - iOS: 44
  /// - Other platforms: [kToolbarHeight]
  final double? toolbarHeight;

  final double? leadingWidth;
  final double? elevation;
  final double? scrolledUnderElevation;

  /// Enables automatic platform styling.
  final bool adaptive;

  /// Mainly useful for testing or previewing another platform.
  final TargetPlatform? platform;

  const SPAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.showDrawerIcon = false,
    this.onDrawerPressed,
    this.centerTitle,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.titleTextStyle,
    this.shape,
    this.toolbarHeight,
    this.leadingWidth,
    this.elevation = 0,
    this.scrolledUnderElevation,
    this.adaptive = true,
    this.platform,
  }) : assert(
         toolbarHeight == null || toolbarHeight > 0,
         'toolbarHeight must be greater than zero.',
       ),
       assert(
         !showDrawerIcon || leading == null,
         'leading cannot be provided when showDrawerIcon is true.',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetPlatform = platform ?? theme.platform;

    final useIOSStyle = adaptive && targetPlatform == TargetPlatform.iOS;

    final resolvedToolbarHeight =
        toolbarHeight ?? (useIOSStyle ? _iosToolbarHeight : kToolbarHeight);

    final resolvedCenterTitle = centerTitle ?? useIOSStyle;

    final iosBackgroundColor = cupertino.CupertinoDynamicColor.resolve(
      cupertino.CupertinoColors.systemBackground,
      context,
    );

    final iosForegroundColor = cupertino.CupertinoDynamicColor.resolve(
      cupertino.CupertinoColors.label,
      context,
    );

    final iosSeparatorColor = cupertino.CupertinoDynamicColor.resolve(
      cupertino.CupertinoColors.separator,
      context,
    );

    final resolvedBackgroundColor =
        backgroundColor ??
        (useIOSStyle
            ? iosBackgroundColor
            : theme.brightness == Brightness.dark
            ? Colors.black
            : theme.colorScheme.primary);

    final resolvedForegroundColor =
        foregroundColor ??
        (useIOSStyle
            ? iosForegroundColor
            : theme.brightness == Brightness.dark
            ? Colors.white
            : theme.colorScheme.onPrimary);

    final materialTitleStyle =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 18);

    final iosTitleStyle = cupertino.CupertinoTheme.of(
      context,
    ).textTheme.navTitleTextStyle;

    final resolvedTitleStyle =
        titleTextStyle ??
        (useIOSStyle ? iosTitleStyle : materialTitleStyle).copyWith(
          color: resolvedForegroundColor,
          fontWeight: useIOSStyle ? FontWeight.w600 : FontWeight.w700,
        );

    final resolvedShape =
        shape ??
        (useIOSStyle
            ? Border(bottom: BorderSide(color: iosSeparatorColor, width: 0))
            : null);

    return AppBar(
      leading: showDrawerIcon
          ? DrawerButton(onPressed: onDrawerPressed)
          : leading,
      automaticallyImplyLeading: showDrawerIcon
          ? false
          : automaticallyImplyLeading,
      leadingWidth: leadingWidth ?? (useIOSStyle ? 44 : null),
      title: titleWidget ?? Text(title),
      titleTextStyle: resolvedTitleStyle,
      actions: actions,
      centerTitle: resolvedCenterTitle,
      bottom: bottom,
      toolbarHeight: resolvedToolbarHeight,
      backgroundColor: resolvedBackgroundColor,
      foregroundColor: resolvedForegroundColor,
      elevation: elevation,
      scrolledUnderElevation:
          scrolledUnderElevation ?? (useIOSStyle ? 0.1 : null),
      shadowColor: shadowColor ?? (useIOSStyle ? iosSeparatorColor : null),
      surfaceTintColor:
          surfaceTintColor ?? (useIOSStyle ? Colors.transparent : null),
      shape: resolvedShape,
      iconTheme: IconThemeData(color: resolvedForegroundColor),
      actionsIconTheme: IconThemeData(color: resolvedForegroundColor),
    );
  }

  @override
  Size get preferredSize {
    final targetPlatform = platform ?? defaultTargetPlatform;

    final useIOSStyle = adaptive && targetPlatform == TargetPlatform.iOS;

    final resolvedToolbarHeight =
        toolbarHeight ?? (useIOSStyle ? _iosToolbarHeight : kToolbarHeight);

    final bottomHeight = bottom?.preferredSize.height ?? 0;

    return Size.fromHeight(resolvedToolbarHeight + bottomHeight);
  }
}
