import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/forms.dart';

void main() {
  test('validators compose and preserve first failure', () {
    final validator = SPValidators.compose<String>([
      SPValidators.required(),
      SPValidators.minLength(4),
      SPValidators.email(),
    ]);

    expect(validator(''), 'This field is required.');
    expect(validator('a@b'), 'Enter at least 4 characters.');
    expect(validator('abcd'), 'Enter a valid email address.');
    expect(validator('a@bc.de'), isNull);
  });

  testWidgets('controller validates and prevents concurrent submissions', (
    tester,
  ) async {
    final key = GlobalKey<FormState>();
    final controller = SPFormController();
    addTearDown(controller.dispose);
    final completer = Completer<int>();
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Form(
          key: key,
          child: const SPTextFormField(initialValue: 'valid'),
        ),
      ),
    );

    final first = controller.submit<int>(
      formKey: key,
      action: () {
        calls++;
        return completer.future;
      },
    );
    expect(controller.isSubmitting, isTrue);

    final second = await controller.submit<int>(
      formKey: key,
      action: () async {
        calls++;
        return 2;
      },
    );

    expect(second, isNull);
    expect(calls, 1);

    completer.complete(7);
    expect(await first, 7);
    expect(controller.isSubmitting, isFalse);
  });

  testWidgets('form inputs integrate with Form validation', (tester) async {
    final key = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Form(
            key: key,
            child: Column(
              children: [
                SPTextFormField(
                  label: 'Email',
                  validator: SPValidators.compose([
                    SPValidators.required(),
                    SPValidators.email(),
                  ]),
                ),
                SPDropdownFormField<int>(
                  label: 'Type',
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('One')),
                    DropdownMenuItem(value: 2, child: Text('Two')),
                  ],
                  onChanged: (_) {},
                  validator: (value) => value == null ? 'Choose one.' : null,
                ),
                SPCheckboxFormField(
                  title: 'Accept',
                  validator: (value) => value == true ? null : 'Required.',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(key.currentState?.validate(), isFalse);

    await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('One').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(key.currentState?.validate(), isTrue);
  });
}
