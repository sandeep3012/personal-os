import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows a CircularProgressIndicator by default', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingState()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a SkeletonList when skeleton is true', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingState(skeleton: true)));
    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('exposes a Loading semantic label', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingState()));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });
}
