import 'package:application/application.dart';
import 'package:test/test.dart';

void main() {
  test('application barrel exports resolve without error', () {
    // Verify that the most commonly used types are reachable via the barrel.
    // If any export is broken the import above will cause a compile error.
    expect(StartupPipeline.new, isNotNull);
    expect(RouteRegistry.new, isNotNull);
    expect(ApplicationRouter.new, isNotNull);
    expect(ApplicationModule.new, isNotNull);
  });
}
