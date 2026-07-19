import 'package:application/application.dart';

/// Route definitions for the Finance feature.
///
/// Register these in [FinanceModule.registerRoutes] so [RouteRegistry]
/// tracks them. The app layer (`apps/mobile`) will use these constants to
/// build matching `GoRoute` entries once a presentation-to-navigation
/// wiring step exists — that wiring is not part of this step.
///
/// Only Core MVP capabilities (DOC-031 §3.1 — Accounts, Transactions,
/// Categories) have routes. Budgets and a dedicated Settings screen are
/// DOC-031 §3.2 "Future" scope and have no route yet — inventing one now
/// would be scope creep beyond what is actually required.
abstract final class FinanceRoutes {
  /// The feature root — entry point shown by [FinanceHomePage].
  static const root = RouteDefinition(
    path: '/finance',
    name: 'finance',
  );

  /// The account list screen.
  static const accounts = RouteDefinition(
    path: '/finance/accounts',
    name: 'finance-accounts',
  );

  /// The transaction list screen.
  static const transactions = RouteDefinition(
    path: '/finance/transactions',
    name: 'finance-transactions',
  );

  /// The category list screen.
  static const categories = RouteDefinition(
    path: '/finance/categories',
    name: 'finance-categories',
  );
}
