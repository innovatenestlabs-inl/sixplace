import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/layout.dart';

void main() {
  const firstKey = Key('first');
  const secondKey = Key('second');

  Widget harness({required double width, required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  testWidgets('changes layout without duplicate widget trees', (
    WidgetTester tester,
  ) async {
    Widget responsiveCards() {
      return const SPRow(
        children: [
          SPCol(md: 6, child: SizedBox(key: firstKey, height: 20)),
          SPCol(md: 6, child: SizedBox(key: secondKey, height: 20)),
        ],
      );
    }

    await tester.pumpWidget(harness(width: 600, child: responsiveCards()));

    expect(tester.getSize(find.byKey(firstKey)).width, closeTo(600, 0.01));

    expect(tester.getSize(find.byKey(secondKey)).width, closeTo(600, 0.01));

    expect(
      tester.getTopLeft(find.byKey(secondKey)).dy,
      greaterThan(tester.getTopLeft(find.byKey(firstKey)).dy),
    );

    await tester.pumpWidget(harness(width: 800, child: responsiveCards()));

    expect(tester.getSize(find.byKey(firstKey)).width, closeTo(400, 0.01));

    expect(tester.getSize(find.byKey(secondKey)).width, closeTo(400, 0.01));

    expect(
      tester.getTopLeft(find.byKey(secondKey)).dy,
      tester.getTopLeft(find.byKey(firstKey)).dy,
    );
  });

  testWidgets('wraps when total spans exceed twelve', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness(
        width: 600,
        child: const SPRow(
          children: [
            SPCol(span: 8, child: SizedBox(key: firstKey, height: 20)),
            SPCol(span: 6, child: SizedBox(key: secondKey, height: 20)),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byKey(firstKey)).width, closeTo(400, 0.01));

    expect(tester.getSize(find.byKey(secondKey)).width, closeTo(300, 0.01));

    expect(
      tester.getTopLeft(find.byKey(secondKey)).dy,
      greaterThan(tester.getTopLeft(find.byKey(firstKey)).dy),
    );
  });

  testWidgets('applies horizontal and vertical gaps', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness(
        width: 800,
        child: const SPRow(
          horizontalGap: 20,
          children: [
            SPCol(md: 6, child: SizedBox(key: firstKey, height: 20)),
            SPCol(md: 6, child: SizedBox(key: secondKey, height: 20)),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byKey(firstKey)).width, closeTo(380, 0.01));

    expect(tester.getSize(find.byKey(secondKey)).width, closeTo(380, 0.01));

    final horizontalContentGap =
        tester.getTopLeft(find.byKey(secondKey)).dx -
        tester.getTopRight(find.byKey(firstKey)).dx;

    expect(horizontalContentGap, closeTo(20, 0.01));

    await tester.pumpWidget(
      harness(
        width: 600,
        child: const SPRow(
          verticalGap: 12,
          children: [
            SPCol(child: SizedBox(key: firstKey, height: 20)),
            SPCol(child: SizedBox(key: secondKey, height: 20)),
          ],
        ),
      ),
    );

    final verticalContentGap =
        tester.getTopLeft(find.byKey(secondKey)).dy -
        tester.getBottomLeft(find.byKey(firstKey)).dy;

    expect(verticalContentGap, closeTo(12, 0.01));
  });

  testWidgets('resolves responsive gap from parent width', (
    WidgetTester tester,
  ) async {
    Widget responsiveRow() {
      return const SPRow(
        responsiveGap: SPResponsiveValue<double>(base: 8, md: 24),
        children: [
          SPCol(span: 6, child: SizedBox(key: firstKey, height: 20)),
          SPCol(span: 6, child: SizedBox(key: secondKey, height: 20)),
        ],
      );
    }

    await tester.pumpWidget(harness(width: 600, child: responsiveRow()));

    var contentGap =
        tester.getTopLeft(find.byKey(secondKey)).dx -
        tester.getTopRight(find.byKey(firstKey)).dx;

    expect(contentGap, closeTo(8, 0.01));

    expect(tester.getSize(find.byKey(firstKey)).width, closeTo(292, 0.01));

    await tester.pumpWidget(harness(width: 800, child: responsiveRow()));

    contentGap =
        tester.getTopLeft(find.byKey(secondKey)).dx -
        tester.getTopRight(find.byKey(firstKey)).dx;

    expect(contentGap, closeTo(24, 0.01));

    expect(tester.getSize(find.byKey(firstKey)).width, closeTo(376, 0.01));
  });

  testWidgets('explicit axis gap overrides responsive general gap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness(
        width: 800,
        child: const SPRow(
          horizontalGap: 10,
          responsiveGap: SPResponsiveValue<double>(base: 8, md: 24),
          children: [
            SPCol(span: 6, child: SizedBox(key: firstKey, height: 20)),
            SPCol(span: 6, child: SizedBox(key: secondKey, height: 20)),
          ],
        ),
      ),
    );

    final contentGap =
        tester.getTopLeft(find.byKey(secondKey)).dx -
        tester.getTopRight(find.byKey(firstKey)).dx;

    expect(contentGap, closeTo(10, 0.01));
  });

  testWidgets('nested rows use allocated parent-column width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness(
        width: 800,
        child: const SPRow(
          children: [
            SPCol(
              md: 6,
              child: SPRow(
                children: [
                  SPCol(span: 6, child: SizedBox(key: firstKey, height: 20)),
                  SPCol(span: 6, child: SizedBox(key: secondKey, height: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byKey(firstKey)).width, closeTo(200, 0.01));

    expect(tester.getSize(find.byKey(secondKey)).width, closeTo(200, 0.01));
  });
}
