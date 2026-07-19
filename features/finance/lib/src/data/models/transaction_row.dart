import 'dart:convert';

import 'package:feature_finance/src/data/schema/finance_schema.dart';

/// A single, unmapped row from the `transactions` table.
///
/// [TransactionRow] is a persistence-layer data shape only — it has no
/// business methods, no validation, and no relationship to the domain
/// `Transaction` entity. Mapping between [TransactionRow] and `Transaction`
/// is a repository-layer concern (Sprint 8B Step 3), not a DAO concern.
final class TransactionRow {
  const TransactionRow({
    required this.transactionId,
    required this.workspaceId,
    required this.accountId,
    this.transferPairId,
    this.categoryId,
    required this.amountMinor,
    required this.currency,
    required this.transactionDate,
    required this.transactionType,
    this.payee,
    this.note,
    this.attachmentIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String transactionId;
  final String workspaceId;
  final String accountId;
  final String? transferPairId;
  final String? categoryId;
  final int amountMinor;
  final String currency;
  final DateTime transactionDate;
  final String transactionType;
  final String? payee;
  final String? note;
  final List<String> attachmentIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Builds a [TransactionRow] from a raw SQL result row.
  factory TransactionRow.fromMap(Map<String, Object?> map) {
    final deletedAtValue = map[FinanceSchema.transactionDeletedAt] as String?;
    final attachmentIdsValue =
        map[FinanceSchema.transactionAttachmentIds] as String?;
    return TransactionRow(
      transactionId: map[FinanceSchema.transactionId]! as String,
      workspaceId: map[FinanceSchema.transactionWorkspaceId]! as String,
      accountId: map[FinanceSchema.transactionAccountId]! as String,
      transferPairId: map[FinanceSchema.transactionTransferPairId] as String?,
      categoryId: map[FinanceSchema.transactionCategoryId] as String?,
      amountMinor: map[FinanceSchema.transactionAmountMinor]! as int,
      currency: map[FinanceSchema.transactionCurrency]! as String,
      transactionDate:
          DateTime.parse(map[FinanceSchema.transactionDate]! as String),
      transactionType: map[FinanceSchema.transactionType]! as String,
      payee: map[FinanceSchema.transactionPayee] as String?,
      note: map[FinanceSchema.transactionNote] as String?,
      attachmentIds: attachmentIdsValue == null
          ? const []
          : (jsonDecode(attachmentIdsValue) as List).cast<String>(),
      createdAt: DateTime.parse(map[FinanceSchema.transactionCreatedAt]! as String),
      updatedAt: DateTime.parse(map[FinanceSchema.transactionUpdatedAt]! as String),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [FinanceSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        FinanceSchema.transactionId: transactionId,
        FinanceSchema.transactionWorkspaceId: workspaceId,
        FinanceSchema.transactionAccountId: accountId,
        FinanceSchema.transactionTransferPairId: transferPairId,
        FinanceSchema.transactionCategoryId: categoryId,
        FinanceSchema.transactionPayee: payee,
        FinanceSchema.transactionType: transactionType,
        FinanceSchema.transactionAmountMinor: amountMinor,
        FinanceSchema.transactionCurrency: currency,
        FinanceSchema.transactionDate: transactionDate.toIso8601String(),
        FinanceSchema.transactionNote: note,
        FinanceSchema.transactionAttachmentIds:
            attachmentIds.isEmpty ? null : jsonEncode(attachmentIds),
        FinanceSchema.transactionCreatedAt: createdAt.toIso8601String(),
        FinanceSchema.transactionUpdatedAt: updatedAt.toIso8601String(),
        FinanceSchema.transactionDeletedAt: deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.transactionId == transactionId &&
          other.workspaceId == workspaceId &&
          other.accountId == accountId &&
          other.transferPairId == transferPairId &&
          other.categoryId == categoryId &&
          other.amountMinor == amountMinor &&
          other.currency == currency &&
          other.transactionDate == transactionDate &&
          other.transactionType == transactionType &&
          other.payee == payee &&
          other.note == note &&
          _listEquals(other.attachmentIds, attachmentIds) &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        transactionId,
        workspaceId,
        accountId,
        transferPairId,
        categoryId,
        amountMinor,
        currency,
        transactionDate,
        transactionType,
        payee,
        note,
        Object.hashAll(attachmentIds),
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() =>
      'TransactionRow(transactionId: $transactionId, type: $transactionType)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
