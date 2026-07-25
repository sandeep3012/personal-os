import 'package:platform_storage/migrations/migration_context.dart';

/// Records every executed SQL statement for schema-validation assertions.
/// Mirrors Notes' `FakeMigrationContext` exactly.
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
