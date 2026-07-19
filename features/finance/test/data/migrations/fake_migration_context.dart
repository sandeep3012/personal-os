import 'package:platform_storage/migrations/migration_context.dart';

/// Records every executed SQL statement for schema-validation assertions.
///
/// Mirrors the shape of `platform_storage`'s own test fake — this package
/// cannot import that fake directly since it lives under `platform_storage`'s
/// `test/` directory, which is not part of its public API.
final class FakeMigrationContext implements MigrationContext {
  FakeMigrationContext({this.version = 0});

  @override
  final int version;

  final executedStatements = <String>[];

  @override
  Future<void> execute(String statement) async =>
      executedStatements.add(statement);

  @override
  Future<void> executeWithArgs(
    String statement,
    List<Object?> arguments,
  ) async {
    executedStatements.add('$statement [args: $arguments]');
  }
}
