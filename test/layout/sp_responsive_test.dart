import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/layout.dart';

void main() {
  group('SPResponsive', () {
    test('classifies standard viewport sizes', () {
      final mobile = SPResponsive.fromSize(const Size(575, 800));

      final tablet = SPResponsive.fromSize(const Size(800, 1000));

      final desktop = SPResponsive.fromSize(const Size(1200, 800));

      final largeDesktop = SPResponsive.fromSize(const Size(1400, 900));

      expect(mobile.breakpoint, SPBreakpoint.xs);
      expect(mobile.isMobile, isTrue);
      expect(mobile.isTablet, isFalse);
      expect(mobile.isDesktop, isFalse);

      expect(tablet.breakpoint, SPBreakpoint.md);
      expect(tablet.isMobile, isFalse);
      expect(tablet.isTablet, isTrue);
      expect(tablet.isDesktop, isFalse);

      expect(desktop.breakpoint, SPBreakpoint.xl);
      expect(desktop.isDesktop, isTrue);
      expect(desktop.isLargeDesktop, isFalse);

      expect(largeDesktop.breakpoint, SPBreakpoint.xxl);
      expect(largeDesktop.isDesktop, isTrue);
      expect(largeDesktop.isLargeDesktop, isTrue);
    });

    test('supports atLeast and below breakpoint checks', () {
      final responsive = SPResponsive.fromSize(const Size(1000, 800));

      expect(responsive.breakpoint, SPBreakpoint.lg);
      expect(responsive.atLeast(SPBreakpoint.md), isTrue);
      expect(responsive.atLeast(SPBreakpoint.lg), isTrue);
      expect(responsive.atLeast(SPBreakpoint.xl), isFalse);

      expect(responsive.below(SPBreakpoint.xl), isTrue);
      expect(responsive.below(SPBreakpoint.lg), isFalse);
    });

    test('resolves nullable responsive values', () {
      const height = SPResponsiveValue<double?>(base: null, lg: 350);

      final mobile = SPResponsive.fromSize(const Size(500, 800));

      final desktop = SPResponsive.fromSize(const Size(1100, 800));

      expect(mobile.resolve(height), isNull);
      expect(desktop.resolve(height), 350);
    });

    test('uses custom breakpoint definitions', () {
      const custom = SPBreakpoints(
        sm: 400,
        md: 600,
        lg: 800,
        xl: 1000,
        xxl: 1200,
      );

      final responsive = SPResponsive.fromSize(
        const Size(850, 700),
        breakpoints: custom,
      );

      expect(responsive.breakpoint, SPBreakpoint.lg);
      expect(responsive.isDesktop, isTrue);
      expect(responsive.breakpoints, custom);
    });
  });

  testWidgets('context.sp reads current MediaQuery size', (
    WidgetTester tester,
  ) async {
    late SPResponsive responsive;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1000, 700)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (BuildContext context) {
              responsive = context.sp;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(responsive.width, 1000);
    expect(responsive.height, 700);
    expect(responsive.breakpoint, SPBreakpoint.lg);
    expect(responsive.isDesktop, isTrue);
  });

  testWidgets('resolveFrom removes manual MediaQuery resolution', (
    WidgetTester tester,
  ) async {
    const value = SPResponsiveValue<double>(base: 8, md: 16, lg: 24);

    late double resolvedValue;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 700)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (BuildContext context) {
              resolvedValue = value.resolveFrom(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(resolvedValue, 16);
  });

  testWidgets('SPResponsiveSizedBox resolves nullable height automatically', (
    WidgetTester tester,
  ) async {
    const childKey = Key('responsive-sized-box-child');

    Widget harness(double viewportWidth) {
      return MediaQuery(
        data: MediaQueryData(size: Size(viewportWidth, 800)),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SPResponsiveSizedBox(
              height: SPResponsiveValue<double?>(base: null, lg: 350),
              child: SizedBox(key: childKey, width: 20, height: 20),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(harness(500));

    expect(tester.getSize(find.byKey(childKey)).height, closeTo(20, 0.01));

    await tester.pumpWidget(harness(1100));

    expect(tester.getSize(find.byKey(childKey)).height, closeTo(350, 0.01));
  });

  testWidgets('SPContainer resolves responsive padding from parent width', (
    WidgetTester tester,
  ) async {
    const contentKey = Key('container-content');

    Widget harness(double width) {
      return MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: const SPContainer.fluid(
                responsivePadding: SPResponsiveValue<EdgeInsetsGeometry>(
                  base: EdgeInsets.all(8),
                  md: EdgeInsets.all(24),
                ),
                child: SizedBox(
                  key: contentKey,
                  width: double.infinity,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(harness(600));

    expect(tester.getSize(find.byKey(contentKey)).width, closeTo(584, 0.01));

    await tester.pumpWidget(harness(800));

    expect(tester.getSize(find.byKey(contentKey)).width, closeTo(752, 0.01));
  });
}
