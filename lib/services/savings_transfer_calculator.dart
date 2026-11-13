import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/wallet_entry.dart';
import 'daily_budget_planner.dart';

/// Allocation logic only. Does not create income, expenses, or Firebase writes.
class SavingsTransferCalculator {
  const SavingsTransferCalculator();

  WalletEntry topUp({
    required BudgetLedger ledger,
    required int amountMinor,
    required String id,
    required DateTime now,
  }) {
    _positive(amountMinor);
    if (amountMinor > ledger.availableToSaveMinor) {
      throw StateError(
        'Not enough unallocated bank + cash. Add income or correct your balance first.',
      );
    }
    return WalletEntry(
      id: id,
      relatedDay: DailyBudgetPlanner.dateKey(now.toLocal()),
      date: now,
      amountMinor: amountMinor,
      type: WalletEntryType.deposit,
      source: WalletEntrySource.manualTopUp,
    );
  }

  WalletEntry toGoal({
    required BudgetLedger ledger,
    required int amountMinor,
    required String goalId,
    required String id,
    required DateTime now,
  }) {
    _positive(amountMinor);
    final matches = ledger.goals.where((goal) => goal.id == goalId);
    if (matches.isEmpty) throw StateError('This goal is no longer available.');
    if (amountMinor > ledger.walletBalanceMinor) {
      throw StateError('Not enough money in your savings wallet.');
    }
    if (amountMinor > ledger.goalRemainingMinor(matches.first)) {
      throw StateError('Enter no more than the remaining goal target.');
    }
    return WalletEntry(
      id: id,
      relatedDay: DailyBudgetPlanner.dateKey(now.toLocal()),
      date: now,
      amountMinor: amountMinor,
      type: WalletEntryType.withdraw,
      source: WalletEntrySource.goalTransfer,
      goalId: goalId,
    );
  }

  static void _positive(int amount) {
    if (amount <= 0) throw ArgumentError('Enter an amount greater than zero.');
  }
}
