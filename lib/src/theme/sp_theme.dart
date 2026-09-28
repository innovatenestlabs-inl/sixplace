import 'package:flutter/material.dart';

/// Spacing scale used by Sixplace theme tokens.
@immutable
class SPSpacingTokens {
  /// Creates a spacing scale.
  const SPSpacingTokens({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  }) : assert(xs >= 0),
       assert(sm >= xs),
       assert(md >= sm),
       assert(lg >= md),
       assert(xl >= lg),
       assert(xxl >= xl);

  /// Extra-small spacing.
  final double xs;

  /// Small spacing.
  final double sm;

  /// Medium spacing.
  final double md;

  /// Large spacing.
  final double lg;

  /// Extra-large spacing.
  final double xl;

  /// Largest default spacing token.
  final double xxl;

  /// Returns a copy with selected values replaced.
  SPSpacingTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) => SPSpacingTokens(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    xxl: xxl ?? this.xxl,
  );

  /// Linearly interpolates between two spacing scales.
  static SPSpacingTokens lerp(
    SPSpacingTokens a,
    SPSpacingTokens b,
    double t,
  ) => SPSpacingTokens(
    xs: _lerpDouble(a.xs, b.xs, t),
    sm: _lerpDouble(a.sm, b.sm, t),
    md: _lerpDouble(a.md, b.md, t),
    lg: _lerpDouble(a.lg, b.lg, t),
    xl: _lerpDouble(a.xl, b.xl, t),
    xxl: _lerpDouble(a.xxl, b.xxl, t),
  );
}

/// Border-radius scale used by Sixplace components.
@immutable
class SPRadiusTokens {
  /// Creates a radius scale.
  const SPRadiusTokens({
    this.sm = 6,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.pill = 999,
  }) : assert(sm >= 0),
       assert(md >= sm),
       assert(lg >= md),
       assert(xl >= lg),
       assert(pill >= xl);

  /// Small radius.
  final double sm;

  /// Medium radius.
  final double md;

  /// Large radius.
  final double lg;

  /// Extra-large radius.
  final double xl;

  /// Very large radius for pill-shaped controls.
  final double pill;

  /// Returns a copy with selected values replaced.
  SPRadiusTokens copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? pill,
  }) => SPRadiusTokens(
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    pill: pill ?? this.pill,
  );

  /// Linearly interpolates between two radius scales.
  static SPRadiusTokens lerp(
    SPRadiusTokens a,
    SPRadiusTokens b,
    double t,
  ) => SPRadiusTokens(
    sm: _lerpDouble(a.sm, b.sm, t),
    md: _lerpDouble(a.md, b.md, t),
    lg: _lerpDouble(a.lg, b.lg, t),
    xl: _lerpDouble(a.xl, b.xl, t),
    pill: _lerpDouble(a.pill, b.pill, t),
  );
}

/// Typography size tokens that can be applied to a Flutter [TextTheme].
@immutable
class SPTypographyTokens {
  /// Creates the default typography scale.
  const SPTypographyTokens({
    this.display = 32,
    this.headline = 24,
    this.title = 20,
    this.body = 16,
    this.label = 14,
    this.caption = 12,
  }) : assert(display >= headline),
       assert(headline >= title),
       assert(title >= body),
       assert(body >= label),
       assert(label >= caption),
       assert(caption > 0);

  /// Display text size.
  final double display;

  /// Headline text size.
  final double headline;

  /// Title text size.
  final double title;

  /// Body text size.
  final double body;

  /// Label text size.
  final double label;

  /// Caption/supporting text size.
  final double caption;

  /// Returns a copy with selected values replaced.
  SPTypographyTokens copyWith({
    double? display,
    double? headline,
    double? title,
    double? body,
    double? label,
    double? caption,
  }) => SPTypographyTokens(
    display: display ?? this.display,
    headline: headline ?? this.headline,
    title: title ?? this.title,
    body: body ?? this.body,
    label: label ?? this.label,
    caption: caption ?? this.caption,
  );

  /// Applies the token sizes while preserving the base styles' other fields.
  TextTheme apply(TextTheme base) => base.copyWith(
    displayLarge: _fontSize(base.displayLarge, display),
    headlineMedium: _fontSize(base.headlineMedium, headline),
    titleLarge: _fontSize(base.titleLarge, title),
    bodyMedium: _fontSize(base.bodyMedium, body),
    labelLarge: _fontSize(base.labelLarge, label),
    bodySmall: _fontSize(base.bodySmall, caption),
  );

  /// Linearly interpolates between two typography scales.
  static SPTypographyTokens lerp(
    SPTypographyTokens a,
    SPTypographyTokens b,
    double t,
  ) => SPTypographyTokens(
    display: _lerpDouble(a.display, b.display, t),
    headline: _lerpDouble(a.headline, b.headline, t),
    title: _lerpDouble(a.title, b.title, t),
    body: _lerpDouble(a.body, b.body, t),
    label: _lerpDouble(a.label, b.label, t),
    caption: _lerpDouble(a.caption, b.caption, t),
  );
}

/// Semantic colors, spacing, radii and typography carried through Flutter's theme system.
///
/// Add this extension using [SPTheme.light], [SPTheme.dark] or
/// [SPTheme.withTokens], then read it with `context.spTheme`.
@immutable
class SPThemeTokens extends ThemeExtension<SPThemeTokens> {
  /// Creates a token set.
  const SPThemeTokens({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    this.spacing = const SPSpacingTokens(),
    this.radius = const SPRadiusTokens(),
    this.typography = const SPTypographyTokens(),
  });

  /// Semantic success color.
  final Color success;

  /// Foreground color placed on [success].
  final Color onSuccess;

  /// Semantic warning color.
  final Color warning;

  /// Foreground color placed on [warning].
  final Color onWarning;

  /// Semantic information color.
  final Color info;

  /// Foreground color placed on [info].
  final Color onInfo;

  /// Application spacing scale.
  final SPSpacingTokens spacing;

  /// Application border-radius scale.
  final SPRadiusTokens radius;

  /// Application typography scale.
  final SPTypographyTokens typography;

  /// Creates sensible semantic tokens from a Material [ColorScheme].
  factory SPThemeTokens.fromColorScheme(
    ColorScheme scheme, {
    SPSpacingTokens spacing = const SPSpacingTokens(),
    SPRadiusTokens radius = const SPRadiusTokens(),
    SPTypographyTokens typography = const SPTypographyTokens(),
  }) {
    final dark = scheme.brightness == Brightness.dark;
    return SPThemeTokens(
      success: dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
      onSuccess: dark ? const Color(0xFF102312) : Colors.white,
      warning: dark ? const Color(0xFFFFB74D) : const Color(0xFFED6C02),
      onWarning: dark ? const Color(0xFF2B1700) : Colors.white,
      info: scheme.primary,
      onInfo: scheme.onPrimary,
      spacing: spacing,
      radius: radius,
      typography: typography,
    );
  }

  @override
  SPThemeTokens copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    SPSpacingTokens? spacing,
    SPRadiusTokens? radius,
    SPTypographyTokens? typography,
  }) => SPThemeTokens(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    info: info ?? this.info,
    onInfo: onInfo ?? this.onInfo,
    spacing: spacing ?? this.spacing,
    radius: radius ?? this.radius,
    typography: typography ?? this.typography,
  );

  @override
  SPThemeTokens lerp(covariant SPThemeTokens? other, double t) {
    if (other == null) return this;
    return SPThemeTokens(
      success: Color.lerp(success, other.success, t) ?? success,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? onSuccess,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      onWarning: Color.lerp(onWarning, other.onWarning, t) ?? onWarning,
      info: Color.lerp(info, other.info, t) ?? info,
      onInfo: Color.lerp(onInfo, other.onInfo, t) ?? onInfo,
      spacing: SPSpacingTokens.lerp(spacing, other.spacing, t),
      radius: SPRadiusTokens.lerp(radius, other.radius, t),
      typography: SPTypographyTokens.lerp(typography, other.typography, t),
    );
  }
}

/// Theme factory and token utilities for Sixplace applications.
abstract final class SPTheme {
  /// Builds a Material 3 light theme with Sixplace design tokens attached.
  static ThemeData light({
    Color seedColor = const Color(0xFF5B5BD6),
    TextTheme? textTheme,
    SPSpacingTokens spacing = const SPSpacingTokens(),
    SPRadiusTokens radius = const SPRadiusTokens(),
    SPTypographyTokens typography = const SPTypographyTokens(),
    SPThemeTokens? tokens,
    bool useMaterial3 = true,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final resolvedTokens =
        tokens ??
        SPThemeTokens.fromColorScheme(
          scheme,
          spacing: spacing,
          radius: radius,
          typography: typography,
        );
    final base = ThemeData(useMaterial3: useMaterial3, colorScheme: scheme);

    return base.copyWith(
      textTheme: textTheme ?? resolvedTokens.typography.apply(base.textTheme),
      extensions: <ThemeExtension<dynamic>>[resolvedTokens],
    );
  }

  /// Builds a Material 3 dark theme with Sixplace design tokens attached.
  static ThemeData dark({
    Color seedColor = const Color(0xFF5B5BD6),
    TextTheme? textTheme,
    SPSpacingTokens spacing = const SPSpacingTokens(),
    SPRadiusTokens radius = const SPRadiusTokens(),
    SPTypographyTokens typography = const SPTypographyTokens(),
    SPThemeTokens? tokens,
    bool useMaterial3 = true,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final resolvedTokens =
        tokens ??
        SPThemeTokens.fromColorScheme(
          scheme,
          spacing: spacing,
          radius: radius,
          typography: typography,
        );
    final base = ThemeData(useMaterial3: useMaterial3, colorScheme: scheme);

    return base.copyWith(
      textTheme: textTheme ?? resolvedTokens.typography.apply(base.textTheme),
      extensions: <ThemeExtension<dynamic>>[resolvedTokens],
    );
  }

  /// Returns [base] with Sixplace tokens installed or replaced.
  ///
  /// Set [applyTypography] to true to apply the resolved Sixplace typography
  /// sizes to the existing [ThemeData.textTheme].
  static ThemeData withTokens(
    ThemeData base, {
    SPThemeTokens? tokens,
    SPSpacingTokens spacing = const SPSpacingTokens(),
    SPRadiusTokens radius = const SPRadiusTokens(),
    SPTypographyTokens typography = const SPTypographyTokens(),
    bool applyTypography = false,
  }) {
    final resolved =
        tokens ??
        SPThemeTokens.fromColorScheme(
          base.colorScheme,
          spacing: spacing,
          radius: radius,
          typography: typography,
        );
    return base.copyWith(
      textTheme: applyTypography
          ? resolved.typography.apply(base.textTheme)
          : null,
      extensions: <ThemeExtension<dynamic>>[
        ...base.extensions.values.where((value) => value is! SPThemeTokens),
        resolved,
      ],
    );
  }
}

/// Convenient access to Sixplace theme tokens from a [BuildContext].
extension SPThemeContext on BuildContext {
  /// Resolves the installed token extension, with a ColorScheme-based fallback.
  SPThemeTokens get spTheme =>
      Theme.of(this).extension<SPThemeTokens>() ??
      SPThemeTokens.fromColorScheme(Theme.of(this).colorScheme);

  /// Resolves the current Sixplace spacing tokens.
  SPSpacingTokens get spSpacing => spTheme.spacing;

  /// Resolves the current Sixplace radius tokens.
  SPRadiusTokens get spRadius => spTheme.radius;

  /// Resolves the current Sixplace typography tokens.
  SPTypographyTokens get spTypography => spTheme.typography;
}

TextStyle _fontSize(TextStyle? style, double size) =>
    (style ?? const TextStyle()).copyWith(fontSize: size);

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
