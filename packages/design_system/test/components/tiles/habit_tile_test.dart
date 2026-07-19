import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the name and streak badge', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HabitTile(
          icon: Icons.water_drop_outlined,
          name: 'Drink Water',
          streakCount: 12,
          completedToday: false,
          onToggle: (_) {},
        ),
      ),
    );

    expect(find.text('Drink Water'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('omits the streak badge when streakCount is zero', (tester) async {
    await tester.pumpWidget(
      _wrap(
        HabitTile(
          icon: Icons.water_drop_outlined,
          name: 'Drink Water',
          streakCount: 0,
          completedToday: false,
          onToggle: (_) {},
        ),
      ),
    );
    expect(find.byType(AmountBadge), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('tapping the checkbox invokes onToggle', (tester) async {
    bool? toggledTo;
    await tester.pumpWidget(
      _wrap(
        HabitTile(
          icon: Icons.water_drop_outlined,
          name: 'Drink Water',
          streakCount: 1,
          completedToday: false,
          onToggle: (value) => toggledTo = value,
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    expect(toggledTo, isTrue);
  });
}
