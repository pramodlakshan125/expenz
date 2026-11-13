import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/services/daily_budget_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settings = DailyBudgetSettings(
    dailyLimitMinor: 50000,
    startDate: DateTime(2026, 4, 1),
  );
  TransactionModel expense(double amount, DateTime date) => TransactionModel(
    id: '$date',
    title: 'Expense',
    category: 'Other',
    amount: amount,
    date: date,
    type: TransactionType.expense,
  );
  const planner = DailyBudgetPlanner();

  test(
    'missed days are ordered and provisional debt reduces today’s limit',
    () {
      final plan = planner.build(
        settings: settings,
        now: DateTime(2026, 4, 4),
        transactions: [expense(700, DateTime(2026, 4, 1))],
        settlements: [],
      );
      expect(plan.unsettledCount, 3);
      expect(plan.nextUnsettledDay!.date, DateTime(2026, 4, 1));
      expect(plan.today.adjustedLimitMinor, 49310);
      expect(plan.today.carriedBeforeMinor, 18620);
    },
  );

  test('a closed day does not change after its transactions are edited', () {
    final closed = DailySettlement(
      date: DateTime(2026, 4, 1),
      baseLimitMinor: 50000,
      adjustedLimitMinor: 50000,
      spentMinor: 70000,
      action: SettlementAction.carriedForward,
      walletChangeMinor: 0,
      carriedBeforeMinor: 0,
      carryAssignedMinor: 0,
    );
    final plan = planner.build(
      settings: settings,
      now: DateTime(2026, 4, 2),
      transactions: [expense(100, DateTime(2026, 4, 1))],
      settlements: [closed],
    );
    expect(plan.unsettledCount, 0);
    expect(plan.today.carriedBeforeMinor, 20000);
    expect(plan.today.adjustedLimitMinor, 49310);
  });

  test('no savings days are generated before setup or for today', () {
    final plan = planner.build(
      settings: settings,
      now: DateTime(2026, 4, 1, 23),
      transactions: [],
      settlements: [],
    );
    expect(plan.unsettledCount, 0);
    expect(plan.nextUnsettledDay, isNull);
    expect(plan.today.progress, 0);
  });

  test('unreviewed previous month overspend does not reduce the new month', () {
    final plan = planner.build(
      settings: DailyBudgetSettings(
        dailyLimitMinor: 50000,
        startDate: DateTime(2026, 4, 30),
      ),
      now: DateTime(2026, 5, 1),
      transactions: [expense(1000, DateTime(2026, 4, 30))],
      settlements: [],
    );
    expect(plan.unsettledCount, 1);
    expect(plan.today.adjustedLimitMinor, 50000);
    expect(plan.today.carriedBeforeMinor, 0);
  });
}
