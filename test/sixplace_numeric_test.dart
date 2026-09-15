import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/sixplace.dart';

void main() {
  group('SixPlace numeric sizing and typography', () {
    testWidgets('resolves .w and .h using logical design scaling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 844) * 1;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              SixPlace.init(
                context,
                designSize: const Size(390, 844),
                rootFontSize: 16,
              );

              final widthScale = MediaQuery.sizeOf(context).width / 390;
              final heightScale = MediaQuery.sizeOf(context).height / 844;

              expect(100.w, closeTo(100 * widthScale, 1e-6));
              expect(48.h, closeTo(48 * heightScale, 1e-6));
              return const SizedBox();
            },
          ),
        ),
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('uses width-based design scaling for .sp and .rem', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 844) * 1;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(780, 844),
            textScaler: TextScaler.linear(1.5),
          ),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                SixPlace.init(
                  context,
                  designSize: const Size(390, 844),
                  rootFontSize: 16,
                );

                final widthScale = MediaQuery.sizeOf(context).width / 390;
                final expectedFont = TextScaler.linear(
                  1.5,
                ).scale(16 * widthScale);
                final expectedRem = TextScaler.linear(
                  1.5,
                ).scale(16 * widthScale);

                expect(16.sp, closeTo(expectedFont, 1e-6));
                expect(1.rem, closeTo(expectedRem, 1e-6));
                expect(
                  2.rem,
                  closeTo(TextScaler.linear(1.5).scale(32 * widthScale), 1e-6),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('resolves em from the inherited DefaultTextStyle font size', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 1;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 18),
            child: Builder(
              builder: (context) {
                SixPlace.init(
                  context,
                  designSize: const Size(390, 844),
                  rootFontSize: 16,
                );

                expect(1.5.em(context), closeTo(27.0, 1e-6));
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('falls back when DefaultTextStyle has no inherited font size', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 1;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.noScaling,
          ),
          child: MaterialApp(
            home: DefaultTextStyle(
              style: const TextStyle(),
              child: Builder(
                builder: (context) {
                  SixPlace.init(
                    context,
                    designSize: const Size(390, 844),
                    rootFontSize: 16,
                  );

                  expect(1.5.em(context), closeTo(24.0, 1e-6));
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('throws for invalid initialization arguments', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                () => SixPlace.init(
                  context,
                  designSize: const Size(0, 844),
                  rootFontSize: 16,
                ),
                throwsArgumentError,
              );

              expect(
                () => SixPlace.init(
                  context,
                  designSize: const Size(390, 844),
                  rootFontSize: 0,
                ),
                throwsArgumentError,
              );

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
