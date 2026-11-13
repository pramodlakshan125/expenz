import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:expenz/models/transaction_model.dart';

export 'package:expenz/models/daily_settlement.dart' show SettlementAction;

/// Every money value is in cents, not rupees.
typedef DailyBudgetResult = ({
  DateTime date,
  int baseLimitMinor,
  int adjustedLimitMinor,
  int spentMinor,
  int remainingMinor,
  int leftoverMinor,
  int overspentMinor,
  int carriedBeforeMinor,
  int carryAssignedMinor,
  int remainingDaysIncludingToday,
  double progress,
});

typedef DaySettlementResult = ({
  DailyBudgetResult day,
  SettlementAction action,
  int walletChangeMinor,
  int walletAfterMinor,
  int uncoveredMinor,
  int carriedAfterMinor,
});

/// Pure phone-side calculations: no Firebase, writes, or system clock.
///
/// Calculate and settle missed days in calendar order. Feed each settlement's
/// carriedAfterMinor into the next day, with the settled day's month. A new
/// month automatically starts without the previous month's carried amount.
class DailyBudgetCalculator {
  const DailyBudgetCalculator();

  DailyBudgetResult calculate({
    required DailyBudgetSettings settings,
    required DateTime day,
    required Iterable<TransactionModel> transactions,
    int carriedOverspendMinor = 0,
    DateTime? carriedMonth,
  }) {
    _nonNegative(carriedOverspendMinor, 'carriedOverspendMinor');
    if (carriedOverspendMinor > 0 && carriedMonth == null) {
      throw ArgumentError('Provide the month that the overspend belongs to.');
    }

    final date = _localDay(day);
    if (date.isBefore(settings.startDate)) {
      throw ArgumentError('Cannot calculate days before the budget starts.');
    }
    final debtMonth = carriedMonth == null ? null : _localDay(carriedMonth);
    final debt = debtMonth?.year == date.year && debtMonth?.month == date.month
        ? carriedOverspendMinor
        : 0;
    final daysLeft = DateTime(date.year, date.month + 1, 0).day - date.day + 1;

    // Give any leftover cents to the earliest days. For example, 100 cents
    // across three days becomes 34, 33, 33, without losing or inventing money.
    final share = (debt + daysLeft - 1) ~/ daysLeft;
    final assigned = share > settings.dailyLimitMinor
        ? settings.dailyLimitMinor
        : share;
    final adjusted = settings.dailyLimitMinor - assigned;

    var spent = 0;
    for (final transaction in transactions) {
      if (transaction.isIncome || _localDay(transaction.date) != date) continue;
      if (!transaction.amount.isFinite || transaction.amount < 0) {
        throw ArgumentError('Expense amounts must be finite and non-negative.');
      }
      spent += (transaction.amount * 100).round();
    }

    final remaining = adjusted - spent;
    return (
      date: date,
      baseLimitMinor: settings.dailyLimitMinor,
      adjustedLimitMinor: adjusted,
      spentMinor: spent,
      remainingMinor: remaining,
      leftoverMinor: remaining > 0 ? remaining : 0,
      overspentMinor: remaining < 0 ? -remaining : 0,
      carriedBeforeMinor: debt,
      carryAssignedMinor: assigned,
      remainingDaysIncludingToday: daysLeft,
      progress: adjusted == 0
          ? (spent > 0 ? 1.0 : 0.0)
          : (spent / adjusted).clamp(0.0, 1.0),
    );
  }

  /// [useWallet] is the user's Yes/No answer: save leftover or cover overspend.
  /// The service is responsible for closing each day only once.
  DaySettlementResult settle({
    required DailyBudgetResult day,
    required int walletBalanceMinor,
    required bool useWallet,
  }) {
    _nonNegative(walletBalanceMinor, 'walletBalanceMinor');
    var walletChange = 0;
    var action = SettlementAction.none;

    if (day.leftoverMinor > 0 && useWallet) {
      walletChange = day.leftoverMinor;
      action = SettlementAction.savedToWallet;
    } else if (day.overspentMinor > 0) {
      final covered = useWallet
          ? (walletBalanceMinor < day.overspentMinor
                ? walletBalanceMinor
                : day.overspentMinor)
          : 0;
      walletChange = -covered;
      action = covered > 0
          ? SettlementAction.coveredByWallet
          : SettlementAction.carriedForward;
    }

    final uncovered =
        day.overspentMinor + (walletChange < 0 ? walletChange : 0);
    return (
      day: day,
      action: action,
      walletChangeMinor: walletChange,
      walletAfterMinor: walletBalanceMinor + walletChange,
      uncoveredMinor: uncovered,
      // Today's reduction pays down earlier overspend once. Only the unpaid
      // part plus today's new uncovered overspend continues to future days.
      carriedAfterMinor:
          day.carriedBeforeMinor - day.carryAssignedMinor + uncovered,
    );
  }

  static DateTime _localDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static void _nonNegative(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'Must not be negative.');
    }
  }
}
