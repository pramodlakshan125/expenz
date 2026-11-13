import 'daily_budget_settings.dart';
import 'money_account.dart';
import 'debt_account.dart';
import 'daily_settlement.dart';
import 'transaction_model.dart';
import 'wallet_entry.dart';
import 'savings_goal.dart';
import 'goal_contribution.dart';

class BudgetLedger {
  final DailyBudgetSettings? settings;
  final List<MoneyAccount> accounts;
  final List<DebtAccount> debts;
  final List<DebtEntry> debtEntries;
  final List<TransactionModel> transactions;
  final List<DailySettlement> settlements;
  final List<WalletEntry> walletEntries;
  final List<SavingsGoal> goals;
  final List<GoalContribution> goalContributions;
  final bool readyForSettlement;
  final bool hasPendingWrites;
  final bool isFromCache;

  BudgetLedger({
    required this.settings,
    List<MoneyAccount> accounts = const [],
    List<DebtAccount> debts = const [],
    List<DebtEntry> debtEntries = const [],
    required List<TransactionModel> transactions,
    required List<DailySettlement> settlements,
    required List<WalletEntry> walletEntries,
    List<SavingsGoal> goals = const [],
    List<GoalContribution> goalContributions = const [],
    required this.readyForSettlement,
    required this.hasPendingWrites,
    required this.isFromCache,
  }) : accounts = List.unmodifiable(accounts),
       debts = List.unmodifiable(debts),
       debtEntries = List.unmodifiable(debtEntries),
       transactions = List.unmodifiable(transactions),
       settlements = List.unmodifiable(settlements),
       walletEntries = List.unmodifiable(walletEntries),
       goals = List.unmodifiable(goals),
       goalContributions = List.unmodifiable(goalContributions);

  int goalSavedMinor(SavingsGoal goal) =>
      goal.initialSavedMinor +
      goalContributions
          .where((entry) => entry.goalId == goal.id)
          .fold(0, (sum, entry) => sum + entry.amountMinor);

  int goalRemainingMinor(SavingsGoal goal) {
    final remaining = goal.targetMinor - goalSavedMinor(goal);
    return remaining > 0 ? remaining : 0;
  }

  int get goalReservedMinor =>
      goals.fold(0, (sum, goal) => sum + goalSavedMinor(goal));

  /// Wallet and goals are allocations within bank + cash, not extra money.
  int get availableToSaveMinor {
    final available =
        actualBalanceMinor - walletBalanceMinor - goalReservedMinor;
    return available > 0 ? available : 0;
  }

  int get walletBalanceMinor =>
      walletEntries.fold(0, (sum, entry) => sum + entry.signedAmountMinor);

  int get actualBalanceMinor => transactions.fold(
    accounts.fold<int>(0, (sum, account) => sum + account.openingBalanceMinor) +
        debtEntries.fold<int>(0, (sum, entry) => sum + entry.cashChangeMinor),
    (sum, entry) => sum + entry.cashChangeMinor,
  );

  int debtBalanceMinor(DebtKind kind) => debts
      .where((debt) => debt.kind == kind)
      .fold<int>(0, (sum, debt) => sum + debt.remainingMinor);
}
