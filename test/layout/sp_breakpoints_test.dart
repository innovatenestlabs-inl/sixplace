import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/layout.dart';

void main() {
  group('SPBreakpoints', () {
    const breakpoints = SPBreakpoints.bootstrap;

    test('uses Bootstrap-compatible defaults', () {
      expect(breakpoints.sm, 576);
      expect(breakpoints.md, 768);
      expect(breakpoints.lg, 992);
      expect(breakpoints.xl, 1200);
      expect(breakpoints.xxl, 1400);
    });

    test('resolves exact breakpoint boundaries', () {
      expect(breakpoints.resolve(0), SPBreakpoint.xs);

      expect(breakpoints.resolve(575.99), SPBreakpoint.xs);

      expect(breakpoints.resolve(576), SPBreakpoint.sm);

      expect(breakpoints.resolve(767.99), SPBreakpoint.sm);

      expect(breakpoints.resolve(768), SPBreakpoint.md);

      expect(breakpoints.resolve(991.99), SPBreakpoint.md);

      expect(breakpoints.resolve(992), SPBreakpoint.lg);

      expect(breakpoints.resolve(1199.99), SPBreakpoint.lg);

      expect(breakpoints.resolve(1200), SPBreakpoint.xl);

      expect(breakpoints.resolve(1399.99), SPBreakpoint.xl);

      expect(breakpoints.resolve(1400), SPBreakpoint.xxl);
    });

    test('rejects negative and NaN widths', () {
      expect(() => breakpoints.resolve(-1), throwsArgumentError);

      expect(() => breakpoints.resolve(double.nan), throwsArgumentError);
    });

    test('supports custom breakpoints', () {
      const custom = SPBreakpoints(
        sm: 500,
        md: 700,
        lg: 900,
        xl: 1100,
        xxl: 1300,
      );

      expect(custom.resolve(699), SPBreakpoint.sm);

      expect(custom.resolve(700), SPBreakpoint.md);

      expect(custom.minimumWidthOf(SPBreakpoint.xxl), 1300);
    });
  });
}
