import 'package:flutter_test/flutter_test.dart';

import 'package:ui_prototype/app.dart';

void main() {
  testWidgets('PrototypeApp shows the Splash screen on launch', (tester) async {
    await tester.pumpWidget(const PrototypeApp());
    expect(find.text('Personal OS'), findsOneWidget);

    // Splash auto-navigates via Future.delayed — let that timer resolve
    // before the test ends so flutter_test doesn't flag a pending timer.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
