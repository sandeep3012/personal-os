import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';

/// A Transaction aggregate root representing a single financial movement
/// (income, expense, or one leg of a transfer).
///
/// Business invariants enforced here:
/// - [amount] must be positive — Invariant 3.
/// - When [type] is [TransactionType.transfer], [transferCounterpartId] must
///   be set — ensures every transfer leg is structurally linked to its pair.
///
/// Soft-delete state is a repository concern and is NOT present on this entity.
/// Attachment IDs are opaque references owned by the platform attachment
/// service; Finance stores them without interpreting their structure.
final class Transaction {
  Transaction({
    required this.id,
    required this.workspaceId,
    required this.accountId,
    required this.type,
    required this.amount,
    this.categoryId,
    this.payee,
    this.note,
    required this.date,
    this.transferCounterpartId,
    this.attachmentIds = const [],
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (amount.amount <= Decimal.zero) {
      throw FinanceException(
        message: 'Transaction amount must be positive, got ${amount.amount}',
      );
    }
    if (type == TransactionType.transfer && transferCounterpartId == null) {
      throw const FinanceException(
        message: 'A transfer transaction must have a transferCounterpartId',
      );
    }
  }

  final TransactionId id;
  final String workspaceId;
  final AccountId accountId;
  final TransactionType type;

  /// The monetary amount of this transaction. Always positive.
  final Money amount;

  /// Opaque reference to the platform Classification Service category.
  final CategoryId? categoryId;

  final Payee? payee;
  final String? note;
  final TransactionDate date;

  /// For transfer transactions, the [TransactionId] of the paired leg.
  final TransactionId? transferCounterpartId;

  /// Opaque platform attachment references. Empty when no attachments.
  final List<String> attachmentIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this transaction with the supplied fields replaced.
  Transaction copyWith({
    TransactionId? id,
    String? workspaceId,
    AccountId? accountId,
    TransactionType? type,
    Money? amount,
    Object? categoryId = _sentinel,
    Object? payee = _sentinel,
    Object? note = _sentinel,
    TransactionDate? date,
    Object? transferCounterpartId = _sentinel,
    List<String>? attachmentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Transaction(
        id: id ?? this.id,
        workspaceId: workspaceId ?? this.workspaceId,
        accountId: accountId ?? this.accountId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        categoryId:
            categoryId == _sentinel ? this.categoryId : categoryId as CategoryId?,
        payee: payee == _sentinel ? this.payee : payee as Payee?,
        note: note == _sentinel ? this.note : note as String?,
        date: date ?? this.date,
        transferCounterpartId: transferCounterpartId == _sentinel
            ? this.transferCounterpartId
            : transferCounterpartId as TransactionId?,
        attachmentIds: attachmentIds ?? this.attachmentIds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Transaction && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Transaction(id: $id, type: ${type.name}, amount: $amount)';
}

/// Sentinel object used by [Transaction.copyWith] to distinguish an explicit
/// `null` from an absent (keep-existing) argument for nullable fields.
const _sentinel = Object();
