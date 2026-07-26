/// Hardcoded fake data for the UI prototype. No repositories, no database,
/// no ViewModels — plain in-memory values only, per the prototype brief.
library;

class FakeAccount {
  const FakeAccount(this.name, this.icon, this.balance);
  final String name;
  final String icon;
  final double balance;
}

class FakeTransaction {
  const FakeTransaction(this.icon, this.title, this.category, this.account, this.amount, this.group);
  final String icon;
  final String title;
  final String category;
  final String account;
  final double amount; // positive = income, negative = expense
  final String group; // "Today", "Yesterday", ...
}

class FakeTask {
  const FakeTask(this.title, {this.subtitle, this.completed = false});
  final String title;
  final String? subtitle;
  final bool completed;
}

class FakeHabit {
  const FakeHabit(this.icon, this.name, this.progressLabel, this.doneCount, this.totalCount, {this.streak});
  final String icon;
  final String name;
  final String progressLabel;
  final int doneCount;
  final int totalCount;
  final int? streak;
}

class FakeGoal {
  const FakeGoal(this.title, this.currentLabel, this.percent);
  final String title;
  final String currentLabel;
  final double percent; // 0..1
}

class FakeNote {
  const FakeNote(this.title, this.preview, this.timeAgo);
  final String title;
  final String preview;
  final String timeAgo;
}

class FakeEvent {
  const FakeEvent(this.time, this.title);
  final String time;
  final String title;
}

class FakeAsset {
  const FakeAsset(this.icon, this.name, this.value);
  final String icon;
  final String name;
  final double value;
}

class FakeDocument {
  const FakeDocument(this.icon, this.name, this.sizeLabel, this.dateLabel);
  final String icon;
  final String name;
  final String sizeLabel;
  final String dateLabel;
}

abstract final class FakeData {
  static const netWorth = 184200.0;

  static const accounts = [
    FakeAccount('HDFC Savings', '🏦', 52450),
    FakeAccount('ICICI Credit Card', '💳', -8300),
    FakeAccount('Cash', '💵', 2000),
  ];

  static const transactions = [
    FakeTransaction('🍽', 'Lunch', 'Food', 'HDFC', -250, 'Today'),
    FakeTransaction('💼', 'Salary', 'Income', 'HDFC', 45000, 'Yesterday'),
    FakeTransaction('🚕', 'Cab', 'Transport', 'Cash', -180, 'Yesterday'),
    FakeTransaction('🛒', 'Groceries', 'Food', 'HDFC', -1450, 'Yesterday'),
    FakeTransaction('⛽', 'Fuel', 'Transport', 'HDFC', -2000, '2 days ago'),
  ];

  static const tasks = [
    FakeTask('Finish Q3 report', subtitle: 'Due today'),
    FakeTask('Call the bank'),
    FakeTask('Buy groceries', completed: true),
  ];

  static const habits = [
    FakeHabit('💧', 'Drink water', '5/7 today', 5, 7),
    FakeHabit('🏃', 'Morning run', '12-day streak', 1, 1, streak: 12),
    FakeHabit('📖', 'Read 20 min', 'Not done today', 0, 1),
  ];

  static const goals = [
    FakeGoal('Save ₹1,00,000', '₹62,000 of ₹1,00,000', 0.62),
    FakeGoal('Run a 10K', 'Achieved', 1.0),
  ];

  static const notes = [
    FakeNote('Meeting notes', 'Discussed the Finance module roadmap…', '2h ago'),
    FakeNote('Recipe: Pasta', 'Boil water, add salt, cook for 9 minutes…', '3d ago'),
    FakeNote('Gift ideas', 'Mom: scarf. Dad: book on gardening.', '1w ago'),
    FakeNote('Book list', 'Atomic Habits, Deep Work, The Pragmatic…', '2w ago'),
  ];

  static const todayEvents = [
    FakeEvent('9:30 AM', 'Team sync'),
    FakeEvent('1:00 PM', 'Lunch with Priya'),
  ];

  static const assets = [
    FakeAsset('🚗', 'Honda City', 850000),
    FakeAsset('🏠', 'Apartment', 2000000),
  ];

  static const documents = [
    FakeDocument('📄', 'Rental Agreement.pdf', '2.1 MB', '3 Mar 2026'),
    FakeDocument('🖼', 'Insurance Card.jpg', '840 KB', '1 Feb 2026'),
  ];

  static const tasksActiveCount = 2;
  static const tasksCompletedTodayCount = 1;
  static const habitsWeekProgress = 0.75;
}
