import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/feedback.dart';

void main() {
  testWidgets('showMessage displays one transient message', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    final controller = SPFeedback.showMessage(
      context,
      'Saved',
      type: SPFeedbackType.success,
    );
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    controller.close();
    await tester.pumpAndSettle();
  });

  testWidgets('showAlert returns the confirm result', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    final result = SPFeedback.showAlert(
      context,
      title: 'Confirm',
      message: 'Continue?',
      cancelLabel: 'Cancel',
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue?'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('loading handle closes only its loader route', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const Text('Home');
            },
          ),
        ),
      ),
    );

    final handle = SPFeedback.showLoading(context, message: 'Working');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(handle.isVisible, isTrue);
    expect(find.text('Working'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    handle.close();
    handle.close();
    await tester.pump();

    expect(handle.isVisible, isFalse);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Working'), findsNothing);
  });
}
