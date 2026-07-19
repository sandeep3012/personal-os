import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a bottom sheet at compact width', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppInputSurface(
              context,
              title: 'Add Account',
              onSave: () {},
              child: const Text('fields'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomSheetForm), findsOneWidget);
    expect(find.byType(AppFormDialog), findsNothing);
  });

  testWidgets('shows a centered dialog at expanded width', (tester) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showAppInputSurface(
              context,
              title: 'Add Account',
              onSave: () {},
              child: const Text('fields'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppFormDialog), findsOneWidget);
    expect(find.byType(AppBottomSheetForm), findsNothing);
  });
}
