// test/widgets/servings_stepper_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastrobrain/widgets/servings_stepper.dart';
import '../test_utils/test_app_wrapper.dart';

void main() {
  Widget buildStepper({
    required int value,
    required ValueChanged<int> onChanged,
    int min = 1,
  }) {
    return wrapWithLocalizations(
      Scaffold(
        body: ServingsStepper(
          value: value,
          onChanged: onChanged,
          min: min,
        ),
      ),
    );
  }

  group('ServingsStepper', () {
    testWidgets('renders current value correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildStepper(value: 3, onChanged: (_) {}));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('servings_value_display')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('servings_value_display'))).data,
        equals('3'),
      );
    });

    testWidgets('+ button calls onChanged with incremented value',
        (WidgetTester tester) async {
      int capturedValue = 3;

      await tester.pumpWidget(
        buildStepper(value: 3, onChanged: (v) => capturedValue = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('servings_increment_button')));
      await tester.pumpAndSettle();

      expect(capturedValue, equals(4));
    });

    testWidgets('− button calls onChanged with decremented value',
        (WidgetTester tester) async {
      int capturedValue = 3;

      await tester.pumpWidget(
        buildStepper(value: 3, onChanged: (v) => capturedValue = v),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('servings_decrement_button')));
      await tester.pumpAndSettle();

      expect(capturedValue, equals(2));
    });

    testWidgets('− button is disabled when value equals min',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildStepper(value: 1, onChanged: (_) {}));
      await tester.pumpAndSettle();

      final decrementButton = tester.widget<IconButton>(
        find.byKey(const Key('servings_decrement_button')),
      );
      expect(decrementButton.onPressed, isNull);
    });
  });
}
