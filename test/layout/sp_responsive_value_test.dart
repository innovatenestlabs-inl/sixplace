import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/layout.dart';

void main() {
  group('SPResponsiveValue', () {
    const value = SPResponsiveValue<int>(base: 12, md: 6, xl: 4);

    test('uses base value below first override', () {
      expect(value.resolve(375), 12);
      expect(value.resolve(767.99), 12);
    });

    test('activates values at exact boundaries', () {
      expect(value.resolve(768), 6);
      expect(value.resolve(1200), 4);
    });

    test('inherits the closest smaller value', () {
      expect(value.resolve(900), 6);
      expect(value.resolve(1100), 6);
      expect(value.resolve(1600), 4);
    });

    test('uses custom breakpoint boundaries', () {
      const customBreakpoints = SPBreakpoints(
        sm: 400,
        md: 600,
        lg: 800,
        xl: 1000,
        xxl: 1200,
      );

      expect(value.resolve(599, breakpoints: customBreakpoints), 12);

      expect(value.resolve(600, breakpoints: customBreakpoints), 6);

      expect(value.resolve(1000, breakpoints: customBreakpoints), 4);
    });
  });

  group('SPColumnSpec', () {
    test('defaults to a full-width column', () {
      const specification = SPColumnSpec();

      expect(specification.resolve(320), 12);
      expect(specification.resolve(1600), 12);
      expect(specification.widthFactor(800), 1);
    });

    test('resolves a mobile-first specification', () {
      const specification = SPColumnSpec(md: 6, lg: 4);

      expect(specification.resolve(600), 12);
      expect(specification.resolve(768), 6);
      expect(specification.resolve(992), 4);
    });
  });
}
