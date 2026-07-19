import 'package:feature_finance/finance.dart';

/// Seeds a fresh [IFinanceDatabaseExecutor] with realistic Finance sample
/// data for Demo Mode (Milestone 6 Part A).
///
/// Writes directly via `INSERT INTO ...` — the same seam
/// `apps/mobile`'s own bootstrap tests already use to write rows without
/// depending on `feature_finance`'s internal schema/DAO classes (which
/// aren't part of its public barrel). Column names/order here must stay in
/// sync with `FinanceSchema.accountColumns`/`transactionColumns`.
///
/// Amounts are plain integer minor units (paise) — ₹1 = 100 minor units,
/// matching `MoneyMinorUnitsConverter`'s 2-decimal-place INR scale.
abstract final class DemoFinanceSeedData {
  static const _currency = 'INR';

  /// Inserts a complete, realistic demo dataset into [executor] for
  /// [workspaceId]: three accounts (cash, savings, credit card) and ~20
  /// transactions spanning income, expenses across every required category,
  /// and one transfer — all with varied real-world dates and merchants.
  static Future<void> seed(
    IFinanceDatabaseExecutor executor, {
    required String workspaceId,
  }) async {
    final now = DateTime.now();
    String daysAgo(int days) =>
        DateTime(now.year, now.month, now.day).subtract(Duration(days: days)).toIso8601String();
    final createdAt = now.toIso8601String();

    const cashId = 'demo-acc-cash';
    const savingsId = 'demo-acc-savings';
    const creditCardId = 'demo-acc-credit-card';

    Future<void> insertAccount({
      required String id,
      required String name,
      required String type,
      required int openingBalanceMinor,
    }) =>
        executor.execute(
          'INSERT INTO accounts '
          '(account_id, workspace_id, name, account_type, currency, '
          'opening_balance_minor, is_active, created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [id, workspaceId, name, type, _currency, openingBalanceMinor, 1, createdAt, createdAt, null],
        );

    await insertAccount(
      id: cashId,
      name: 'Cash',
      type: 'cash',
      openingBalanceMinor: 350000, // ₹3,500
    );
    await insertAccount(
      id: savingsId,
      name: 'HDFC Savings',
      type: 'savings',
      openingBalanceMinor: 12500000, // ₹1,25,000
    );
    await insertAccount(
      id: creditCardId,
      name: 'ICICI Credit Card',
      type: 'creditCard',
      openingBalanceMinor: 0,
    );

    var seq = 0;
    String nextId() => 'demo-txn-${++seq}';

    Future<void> insertTransaction({
      required String accountId,
      required String type,
      required int amountMinor,
      required String daysAgoIso,
      String? categoryId,
      String? payee,
      String? note,
      String? transferPairId,
      String? id,
    }) async {
      final txnId = id ?? nextId();
      await executor.execute(
        'INSERT INTO transactions '
        '(transaction_id, workspace_id, account_id, transfer_pair_id, category_id, '
        'payee, transaction_type, amount_minor, currency, transaction_date, note, '
        'attachment_ids, created_at, updated_at, deleted_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          txnId,
          workspaceId,
          accountId,
          transferPairId,
          categoryId,
          payee,
          type,
          amountMinor,
          _currency,
          daysAgoIso,
          note,
          null,
          createdAt,
          createdAt,
          null,
        ],
      );
    }

    // Salary — monthly income into HDFC Savings.
    await insertTransaction(
      accountId: savingsId,
      type: 'income',
      amountMinor: 8500000, // ₹85,000
      daysAgoIso: daysAgo(28),
      categoryId: 'Salary',
      payee: 'Acme Technologies Pvt Ltd',
      note: 'Monthly salary',
    );
    await insertTransaction(
      accountId: savingsId,
      type: 'income',
      amountMinor: 8500000,
      daysAgoIso: daysAgo(58),
      categoryId: 'Salary',
      payee: 'Acme Technologies Pvt Ltd',
      note: 'Monthly salary',
    );

    // Food.
    await insertTransaction(
      accountId: cashId,
      type: 'expense',
      amountMinor: 45000,
      daysAgoIso: daysAgo(1),
      categoryId: 'Food',
      payee: 'Swiggy',
      note: 'Dinner order',
    );
    await insertTransaction(
      accountId: creditCardId,
      type: 'expense',
      amountMinor: 128000,
      daysAgoIso: daysAgo(4),
      categoryId: 'Food',
      payee: 'Zomato',
      note: 'Weekend order',
    );
    await insertTransaction(
      accountId: cashId,
      type: 'expense',
      amountMinor: 32000,
      daysAgoIso: daysAgo(9),
      categoryId: 'Food',
      payee: 'Sri Krishna Sweets',
    );

    // Fuel.
    await insertTransaction(
      accountId: creditCardId,
      type: 'expense',
      amountMinor: 250000,
      daysAgoIso: daysAgo(6),
      categoryId: 'Fuel',
      payee: 'Indian Oil',
      note: 'Full tank',
    );
    await insertTransaction(
      accountId: creditCardId,
      type: 'expense',
      amountMinor: 210000,
      daysAgoIso: daysAgo(20),
      categoryId: 'Fuel',
      payee: 'HP Petrol Pump',
    );

    // Shopping.
    await insertTransaction(
      accountId: creditCardId,
      type: 'expense',
      amountMinor: 349900,
      daysAgoIso: daysAgo(11),
      categoryId: 'Shopping',
      payee: 'Amazon',
      note: 'Home essentials',
    );
    await insertTransaction(
      accountId: creditCardId,
      type: 'expense',
      amountMinor: 189900,
      daysAgoIso: daysAgo(23),
      categoryId: 'Shopping',
      payee: 'Flipkart',
    );

    // Entertainment.
    await insertTransaction(
      accountId: savingsId,
      type: 'expense',
      amountMinor: 64900,
      daysAgoIso: daysAgo(15),
      categoryId: 'Entertainment',
      payee: 'Netflix',
      note: 'Monthly subscription',
    );
    await insertTransaction(
      accountId: creditCardId,
      type: 'expense',
      amountMinor: 90000,
      daysAgoIso: daysAgo(18),
      categoryId: 'Entertainment',
      payee: 'BookMyShow',
      note: 'Movie tickets',
    );

    // Utilities.
    await insertTransaction(
      accountId: savingsId,
      type: 'expense',
      amountMinor: 180000,
      daysAgoIso: daysAgo(12),
      categoryId: 'Utilities',
      payee: 'BESCOM',
      note: 'Electricity bill',
    );
    await insertTransaction(
      accountId: savingsId,
      type: 'expense',
      amountMinor: 79900,
      daysAgoIso: daysAgo(14),
      categoryId: 'Utilities',
      payee: 'Airtel',
      note: 'Broadband + mobile',
    );

    // Medical.
    await insertTransaction(
      accountId: cashId,
      type: 'expense',
      amountMinor: 65000,
      daysAgoIso: daysAgo(25),
      categoryId: 'Medical',
      payee: 'Apollo Pharmacy',
    );
    await insertTransaction(
      accountId: creditCardId,
      type: 'expense',
      amountMinor: 80000,
      daysAgoIso: daysAgo(33),
      categoryId: 'Medical',
      payee: 'Practo Consultation',
    );

    // Travel.
    await insertTransaction(
      accountId: creditCardId,
      type: 'expense',
      amountMinor: 320000,
      daysAgoIso: daysAgo(21),
      categoryId: 'Travel',
      payee: 'IRCTC',
      note: 'Train tickets',
    );
    await insertTransaction(
      accountId: cashId,
      type: 'expense',
      amountMinor: 42000,
      daysAgoIso: daysAgo(3),
      categoryId: 'Travel',
      payee: 'Ola',
    );

    // Miscellaneous.
    await insertTransaction(
      accountId: cashId,
      type: 'expense',
      amountMinor: 15000,
      daysAgoIso: daysAgo(2),
      categoryId: 'Miscellaneous',
      payee: 'Sri Ganesh Kirana Store',
    );
    await insertTransaction(
      accountId: savingsId,
      type: 'expense',
      amountMinor: 2000,
      daysAgoIso: daysAgo(7),
      categoryId: 'Miscellaneous',
      payee: 'ATM Withdrawal Fee',
    );

    // One transfer: HDFC Savings -> Cash (an ATM withdrawal), two legs
    // sharing a transfer_pair_id — mirrors TransferService.createTransferPair
    // (debit leg typed `expense` on the source account, credit leg typed
    // `income` on the destination account; presentation layers detect
    // "transfer" via transfer_pair_id being non-null, not the type column).
    final debitId = nextId();
    final creditId = nextId();
    await insertTransaction(
      id: debitId,
      accountId: savingsId,
      type: 'expense',
      amountMinor: 500000,
      daysAgoIso: daysAgo(10),
      note: 'ATM withdrawal',
      transferPairId: creditId,
    );
    await insertTransaction(
      id: creditId,
      accountId: cashId,
      type: 'income',
      amountMinor: 500000,
      daysAgoIso: daysAgo(10),
      note: 'ATM withdrawal',
      transferPairId: debitId,
    );
  }
}
