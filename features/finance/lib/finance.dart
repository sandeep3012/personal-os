/// Personal OS — Finance Feature
///
/// Provides personal financial tracking: accounts, income, expenses,
/// and transfers.
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_finance/finance.dart';
/// ```
library;

// Persistence leaf interfaces + the default in-memory implementation. The
// app layer (composition root) must register a concrete
// IFinanceDatabaseExecutor/IFinanceTransactionRunner binding — via
// InMemoryFinanceDatabaseExecutor/InMemoryFinanceTransactionRunner, or a
// future ADR-approved real storage engine — before any Finance repository
// is resolved. FinanceModule intentionally does not self-register these
// (see FinanceModule.registerServices docs).
export 'src/data/database/file_backed_finance_database_executor.dart';
export 'src/data/database/file_backed_finance_transaction_runner.dart';
export 'src/data/database/i_finance_database_executor.dart';
export 'src/data/database/i_finance_transaction_runner.dart';
export 'src/data/database/in_memory_finance_database_executor.dart';
export 'src/data/database/in_memory_finance_transaction_runner.dart';

// FinanceModule — needed by RuntimeBootstrap to load the Finance feature
// (DOC-031 §7).
export 'src/di/finance_module.dart';

// Navigation — shared drawer + app-layer-provided callbacks (ADR-003).
export 'src/presentation/navigation/finance_nav_callbacks.dart';

// Complete vertical slices (Sprint 8C Steps 4–6): Dashboard, Accounts,
// Transactions/Transfers, Categories.
export 'src/presentation/pages/accounts_page.dart';
export 'src/presentation/pages/categories_page.dart';
export 'src/presentation/pages/finance_home_page.dart';
export 'src/presentation/pages/transactions_page.dart';

// Route constants — needed by the app layer to build go_router entries.
export 'src/presentation/routes/finance_routes.dart';
export 'src/presentation/viewmodels/accounts_view_model.dart';
export 'src/presentation/viewmodels/categories_view_model.dart';
export 'src/presentation/viewmodels/finance_home_view_model.dart';
export 'src/presentation/viewmodels/transactions_view_model.dart';

// Navigation — shared Finance drawer (ADR-003).
export 'src/presentation/widgets/finance_navigation_drawer.dart';
