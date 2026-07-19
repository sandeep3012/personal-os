import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';

/// An Account aggregate root representing a financial account owned by the
/// user within a workspace.
///
/// Business invariants enforced here:
/// - [name] must not be empty (Invariant 1).
///
/// Remaining invariants (currency immutability, deletion guard) are enforced
/// at the use-case layer where the necessary context is available.
final class Account {
  Account({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (name.isEmpty) {
      throw const FinanceException(message: 'Account name must not be empty');
    }
  }

  final AccountId id;
  final String workspaceId;
  final String name;
  final AccountType type;

  /// The account's primary operating currency for all transactions.
  final CurrencyCode currency;

  /// The opening balance when the account was created.
  final Money initialBalance;

  /// Whether the account is open and accepting new transactions.
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this account with the supplied fields replaced.
  Account copyWith({
    AccountId? id,
    String? workspaceId,
    String? name,
    AccountType? type,
    CurrencyCode? currency,
    Money? initialBalance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Account(
        id: id ?? this.id,
        workspaceId: workspaceId ?? this.workspaceId,
        name: name ?? this.name,
        type: type ?? this.type,
        currency: currency ?? this.currency,
        initialBalance: initialBalance ?? this.initialBalance,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Account && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Account(id: $id, name: $name, type: ${type.name})';
}
