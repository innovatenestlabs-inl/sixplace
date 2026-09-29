import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/theme.dart';

class _AppTheme extends ThemeExtension<_AppTheme> {
  const _AppTheme();

  @override
  _AppTheme copyWith() => this;

  @override
  _AppTheme lerp(covariant _AppTheme? other, double t) => this;
}

void main() {
  test('spacing and radius tokens copy and interpolate', () {
    const a = SPSpacingTokens();
    final b = a.copyWith(md: 20, lg: 28, xl: 36, xxl: 52);
    final middle = SPSpacingTokens.lerp(a, b, 0.5);

    expect(middle.md, 18);
    expect(middle.lg, 26);

    const typeA = SPTypographyTokens();
    final typeB = typeA.copyWith(
      body: 18,
      title: 22,
      headline: 26,
      display: 34,
    );
    expect(SPTypographyTokens.lerp(typeA, typeB, 0.5).body, 17);

    const radiusA = SPRadiusTokens();
    final radiusB = radiusA.copyWith(lg: 20, xl: 28, pill: 1000);
    expect(SPRadiusTokens.lerp(radiusA, radiusB, 0.5).lg, 18);
  });

  testWidgets('SPTheme installs tokens and context accessors resolve them', (
    tester,
  ) async {
    late SPThemeTokens tokens;
    await tester.pumpWidget(
      MaterialApp(
        theme: SPTheme.light(
          seedColor: const Color(0xFF123456),
          spacing: const SPSpacingTokens(md: 18, lg: 26, xl: 34, xxl: 50),
        ),
        home: Builder(
          builder: (context) {
            tokens = context.spTheme;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(tokens.spacing.md, 18);
    expect(tokens.typography.body, 16);
    expect(tokens.info, isNotNull);
  });

  test('withTokens preserves unrelated theme extensions', () {
    const appTheme = _AppTheme();
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFF445566),
      extensions: const [appTheme],
    );
    final themed = SPTheme.withTokens(
      base,
      spacing: const SPSpacingTokens(md: 20, lg: 28, xl: 36, xxl: 52),
    );

    expect(themed.extension<SPThemeTokens>()?.spacing.md, 20);
    expect(themed.extension<_AppTheme>(), same(appTheme));
  });
}
