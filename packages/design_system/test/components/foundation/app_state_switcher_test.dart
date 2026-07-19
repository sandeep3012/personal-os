import 'package:application/application.dart' show AsyncState;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/exceptions/unknown_exception.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders LoadingState for the loading variant', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppStateSwitcher<List<int>>(
          state: const AsyncState.loading(),
          successBuilder: (context, data) => Text('items: ${data.length}'),
        ),
      ),
    );
    expect(find.byType(LoadingState), findsOneWidget);
  });

  testWidgets('renders successBuilder content for a non-empty success state',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppStateSwitcher<List<int>>(
          state: const AsyncState.success([1, 2, 3]),
          successBuilder: (context, data) => Text('items: ${data.length}'),
          isEmpty: (data) => data.isEmpty,
        ),
      ),
    );
    expect(find.text('items: 3'), findsOneWidget);
  });

  testWidgets('renders EmptyState when isEmpty returns true', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppStateSwitcher<List<int>>(
          state: const AsyncState.success(<int>[]),
          successBuilder: (context, data) => Text('items: ${data.length}'),
          isEmpty: (data) => data.isEmpty,
          emptyTitle: 'No items',
        ),
      ),
    );
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No items'), findsOneWidget);
  });

  testWidgets('renders ErrorState with the exception message and onRetry',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(
        AppStateSwitcher<List<int>>(
          state: const AsyncState.error(UnknownException(message: 'boom')),
          successBuilder: (context, data) => Text('items: ${data.length}'),
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('boom'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('without isEmpty, a success state never renders EmptyState',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppStateSwitcher<List<int>>(
          state: const AsyncState.success(<int>[]),
          successBuilder: (context, data) => Text('items: ${data.length}'),
        ),
      ),
    );
    expect(find.byType(EmptyState), findsNothing);
    expect(find.text('items: 0'), findsOneWidget);
  });
}
