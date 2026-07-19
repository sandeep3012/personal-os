import 'package:application/application.dart' show AsyncState;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/exceptions/unknown_exception.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders a small progress indicator while loading', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ModuleCard<int>(
          icon: Icons.account_balance_wallet_outlined,
          accentColor: Colors.blue,
          title: 'Finance',
          state: const AsyncState.loading(),
          contentBuilder: (context, data) => Text('value: $data'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders contentBuilder for a success state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ModuleCard<int>(
          icon: Icons.account_balance_wallet_outlined,
          accentColor: Colors.blue,
          title: 'Finance',
          state: const AsyncState.success(42),
          contentBuilder: (context, data) => Text('value: $data'),
        ),
      ),
    );
    expect(find.text('value: 42'), findsOneWidget);
  });

  testWidgets('renders a scoped error message for an error state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ModuleCard<int>(
          icon: Icons.account_balance_wallet_outlined,
          accentColor: Colors.blue,
          title: 'Finance',
          state: const AsyncState.error(UnknownException(message: 'boom')),
          contentBuilder: (context, data) => Text('value: $data'),
        ),
      ),
    );
    expect(find.text("Couldn't load Finance"), findsOneWidget);
  });

  testWidgets('tapping the card invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        ModuleCard<int>(
          icon: Icons.account_balance_wallet_outlined,
          accentColor: Colors.blue,
          title: 'Finance',
          state: const AsyncState.success(1),
          contentBuilder: (context, data) => const Text('content'),
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });

  testWidgets('one card in error state does not affect a sibling card',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            ModuleCard<int>(
              icon: Icons.account_balance_wallet_outlined,
              accentColor: Colors.blue,
              title: 'Finance',
              state: const AsyncState.error(UnknownException(message: 'boom')),
              contentBuilder: (context, data) => const Text('finance content'),
            ),
            ModuleCard<int>(
              icon: Icons.task_outlined,
              accentColor: Colors.purple,
              title: 'Tasks',
              state: const AsyncState.success(5),
              contentBuilder: (context, data) => Text('tasks: $data'),
            ),
          ],
        ),
      ),
    );

    expect(find.text("Couldn't load Finance"), findsOneWidget);
    expect(find.text('tasks: 5'), findsOneWidget);
  });
}
