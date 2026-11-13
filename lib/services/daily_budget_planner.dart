import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:expenz/models/transaction_model.dart';
import 'daily_budget_calculator.dart';

typedef DailyBudgetPlan = ({
  DailyBudgetResult today,
  DailyBudgetResult? nextUnsettledDay,
  int unsettledCount,
});

/// Replays days in calendar order. Saved days are immutable; unresolved days
/// provisionally carry overspend without moving wallet money.
class DailyBudgetPlanner {
  const DailyBudgetPlanner();

  DailyBudgetPlan build({
    required DailyBudgetSettings settings,
    required DateTime now,
    required Iterable<TransactionModel> transactions,
    required Iterable<DailySettlement> settlements,
  }) {
    const calculator = DailyBudgetCalculator();
    final local = now.toLocal();
    final today = DateTime(local.year, local.month, local.day);
    if (today.isBefore(settings.startDate)) {
      throw StateError('Your device date is before your budget start date.');
    }
    final saved = {for (final entry in settlements) entry.dayKey: entry};
    // Group once; do not scan the entire transaction list for every missed day.
    final byDay = <DateTime, List<TransactionModel>>{};
    for (final entry in transactions) {
      final date = entry.date.toLocal();
      final key = DateTime(date.year, date.month, date.day);
      (byDay[key] ??= []).add(entry);
    }
    var debt = 0;
    DateTime? debtMonth;
    DailyBudgetResult? next;
    var count = 0;
    var cursor = settings.startDate;
    while (cursor.isBefore(today)) {
      final key = dateKey(cursor);
      final closed = saved[key];
      if (closed != null) {
        debt = closed.carriedAfterMinor;
      } else {
        final result = calculator.calculate(
          settings: settings,
          day: cursor,
          transactions: byDay[cursor] ?? const [],
          carriedOverspendMinor: debt,
          carriedMonth: debtMonth,
        );
        next ??= result;
        count++;
        debt = calculator
            .settle(day: result, walletBalanceMinor: 0, useWallet: false)
            .carriedAfterMinor;
      }
      debtMonth = cursor;
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }
    return (
      today: calculator.calculate(
        settings: settings,
        day: today,
        transactions: byDay[today] ?? const [],
        carriedOverspendMinor: debt,
        carriedMonth: debtMonth,
      ),
      nextUnsettledDay: next,
      unsettledCount: count,
    );
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
