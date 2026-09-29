import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/sixplace.dart';

import 'package:example/main.dart';
import 'package:example/network_demo_transport.dart';

void main() {
  testWidgets(
    'compact example validates and submits using offline HTTP',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SPNetwork.init(
        config: SPNetworkConfig(baseUrl: 'https://demo.invalid/api/'),
        client: createNetworkDemoTransport(),
        closeClient: true,
      );
      addTearDown(SPNetwork.instance.close);
      await tester.pumpWidget(const SixplaceExampleApp());
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Submit demo'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsOneWidget);
      expect(
        find.text('Last preference: No notes submitted yet.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField), 'Offline note');
      await tester.tap(find.text('Submit demo'));
      await tester.pumpAndSettle();
      expect(find.text('Last preference: Offline note'), findsOneWidget);
      expect(find.text('Cached HTTP status: 201'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
