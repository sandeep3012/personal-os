import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the message and error icon', (tester) async {
    await tester.pumpWidget(_wrap(const ErrorState(message: 'Something failed')));
    expect(find.text('Something failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('omits Retry when onRetry is null', (tester) async {
    await tester.pumpWidget(_wrap(const ErrorState(message: 'failed')));
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('tapping Retry invokes onRetry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(ErrorState(message: 'failed', onRetry: () => retried = true)),
    );
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('the message is announced as a live region', (tester) async {
    await tester.pumpWidget(_wrap(const ErrorState(message: 'failed')));

    final semanticsWidgets = tester.widgetList<Semantics>(find.byType(Semantics));
    expect(semanticsWidgets.any((s) => s.properties.liveRegion == true), isTrue);
  });
}
