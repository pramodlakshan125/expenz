import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/services/daily_budget_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = DailyBudgetCalculator();
  final settings = DailyBudgetSettings(
    dailyLimitMinor: 50000,
    startDate: DateTime(2026, 4, 1),
  );

  TransactionModel transaction(
    double amount,
    DateTime date, {
    TransactionType type = TransactionType.expense,
  }) => TransactionModel(
    id: '$amount-$date-${type.name}',
    title: 'Test transaction',
    category: 'Other',
    amount: amount,
    date: date,
    type: type,
  );

  DailyBudgetResult day({
    DateTime? date,
    double spent = 0,
    int debt = 0,
    DateTime? debtMonth,
  }) {
    final selected = date ?? DateTime(2026, 4, 1);
    return calculator.calculate(
      settings: settings,
      day: selected,
      transactions: [transaction(spent, selected)],
      carriedOverspendMinor: debt,
      carriedMonth: debtMonth,
    );
  }

  test('first day without transactions has an empty bar and full limit', () {
    final result = calculator.calculate(
      settings: settings,
      day: DateTime(2026, 4, 1),
      transactions: [],
    );
    expect(result.spentMinor, 0);
    expect(result.remainingMinor, 50000);
    expect(result.leftoverMinor, 50000);
    expect(result.overspentMinor, 0);
    expect(result.progress, 0);
  });

  test('only expenses on the selected local calendar day count', () {
    final result = calculator.calculate(
      settings: settings,
      day: DateTime(2026, 4, 2, 12),
      transactions: [
        transaction(125.25, DateTime(2026, 4, 2)),
        transaction(24.75, DateTime(2026, 4, 2, 23, 59)),
        transaction(900, DateTime(2026, 4, 1, 23, 59)),
        transaction(900, DateTime(2026, 4, 3)),
        transaction(2000, DateTime(2026, 4, 2), type: TransactionType.income),
      ],
    );
    expect(result.date, DateTime(2026, 4, 2));
    expect(result.spentMinor, 15000);
    expect(result.remainingMinor, 35000);
    expect(result.progress, closeTo(0.3, 0.000001));
  });

  test('exact target has a full bar with no leftover or overspend', () {
    final result = day(spent: 500);
    expect(result.progress, 1);
    expect(result.leftoverMinor, 0);
    expect(result.overspentMinor, 0);
    final settled = calculator.settle(
      day: result,
      walletBalanceMinor: 20000,
      useWallet: true,
    );
    expect(settled.action, SettlementAction.none);
    expect(settled.walletChangeMinor, 0);
  });

  test('overspending fills the bar without exceeding its range', () {
    final result = day(spent: 700);
    expect(result.progress, 1);
    expect(result.remainingMinor, -20000);
    expect(result.overspentMinor, 20000);
    expect(result.leftoverMinor, 0);
  });

  test('saving leftover deposits only the unused adjusted limit', () {
    final result = day(
      date: DateTime(2026, 4, 2),
      spent: 300,
      debt: 20000,
      debtMonth: DateTime(2026, 4, 1),
    );
    expect(result.adjustedLimitMinor, 49310);
    final settled = calculator.settle(
      day: result,
      walletBalanceMinor: 0,
      useWallet: true,
    );
    expect(settled.action, SettlementAction.savedToWallet);
    expect(settled.walletChangeMinor, 19310);
    expect(settled.walletAfterMinor, 19310);
    expect(settled.carriedAfterMinor, 19310);
  });

  test('declining leftover savings leaves the wallet unchanged', () {
    final result = calculator.settle(
      day: day(spent: 300),
      walletBalanceMinor: 5000,
      useWallet: false,
    );
    expect(result.action, SettlementAction.none);
    expect(result.walletChangeMinor, 0);
    expect(result.walletAfterMinor, 5000);
    expect(result.carriedAfterMinor, 0);
  });

  test('wallet fully covers extra without creating new carried debt', () {
    final result = calculator.settle(
      day: day(spent: 650),
      walletBalanceMinor: 20000,
      useWallet: true,
    );
    expect(result.action, SettlementAction.coveredByWallet);
    expect(result.walletChangeMinor, -15000);
    expect(result.walletAfterMinor, 5000);
    expect(result.uncoveredMinor, 0);
    expect(result.carriedAfterMinor, 0);
  });

  test('partial coverage uses the wallet and carries only the difference', () {
    final result = calculator.settle(
      day: day(spent: 650),
      walletBalanceMinor: 5000,
      useWallet: true,
    );
    expect(result.action, SettlementAction.coveredByWallet);
    expect(result.walletAfterMinor, 0);
    expect(result.walletChangeMinor, -5000);
    expect(result.uncoveredMinor, 10000);
    expect(result.carriedAfterMinor, 10000);
  });

  test('empty wallet or declining coverage carries all the extra', () {
    for (final choice in [
      (balance: 0, yes: true),
      (balance: 50000, yes: false),
    ]) {
      final result = calculator.settle(
        day: day(spent: 700),
        walletBalanceMinor: choice.balance,
        useWallet: choice.yes,
      );
      expect(result.action, SettlementAction.carriedForward);
      expect(result.walletAfterMinor, choice.balance);
      expect(result.carriedAfterMinor, 20000);
    }
  });

  test('the corrected three-day example uses adjusted limits throughout', () {
    final first = calculator.settle(
      day: day(spent: 700),
      walletBalanceMinor: 0,
      useWallet: true,
    );
    final second = calculator.settle(
      day: day(
        date: DateTime(2026, 4, 2),
        spent: 300,
        debt: first.carriedAfterMinor,
        debtMonth: first.day.date,
      ),
      walletBalanceMinor: first.walletAfterMinor,
      useWallet: true,
    );
    final third = calculator.settle(
      day: day(
        date: DateTime(2026, 4, 3),
        spent: 650,
        debt: second.carriedAfterMinor,
        debtMonth: second.day.date,
      ),
      walletBalanceMinor: second.walletAfterMinor,
      useWallet: true,
    );
    expect(second.day.adjustedLimitMinor, 49310);
    expect(second.walletAfterMinor, 19310);
    expect(third.day.adjustedLimitMinor, 49310);
    expect(third.day.overspentMinor, 15690);
    expect(third.walletAfterMinor, 3620);
    expect(third.carriedAfterMinor, 18620);
  });

  test('rounding shares every cent once over the remaining days', () {
    var debt = 100;
    final assigned = <int>[];
    for (var date = 28; date <= 30; date++) {
      final result = day(
        date: DateTime(2026, 4, date),
        debt: debt,
        debtMonth: DateTime(2026, 4),
      );
      assigned.add(result.carryAssignedMinor);
      debt = calculator
          .settle(day: result, walletBalanceMinor: 0, useWallet: false)
          .carriedAfterMinor;
    }
    expect(assigned, [34, 33, 33]);
    expect(debt, 0);
  });

  test('large debt stops the limit at zero and keeps unpaid debt', () {
    final result = day(
      date: DateTime(2026, 4, 30),
      spent: 100,
      debt: 100000,
      debtMonth: DateTime(2026, 4),
    );
    expect(result.adjustedLimitMinor, 0);
    expect(result.progress, 1);
    expect(result.overspentMinor, 10000);
    final settled = calculator.settle(
      day: result,
      walletBalanceMinor: 0,
      useWallet: false,
    );
    expect(settled.carriedAfterMinor, 60000);
  });

  test('zero target and no spending produce a finite empty bar', () {
    final result = calculator.calculate(
      settings: DailyBudgetSettings(
        dailyLimitMinor: 0,
        startDate: DateTime(2026, 4, 1),
      ),
      day: DateTime(2026, 4, 1),
      transactions: [],
    );
    expect(result.progress, 0);
    expect(result.progress.isFinite, isTrue);
    expect(result.remainingMinor, 0);
  });

  test('new month and new year reset earlier carried overspend', () {
    for (final dates in [
      (current: DateTime(2026, 5, 1), previous: DateTime(2026, 4, 30)),
      (current: DateTime(2027, 1, 1), previous: DateTime(2026, 12, 31)),
      (current: DateTime(2027, 4, 1), previous: DateTime(2026, 4, 30)),
    ]) {
      final result = day(
        date: dates.current,
        debt: 100000,
        debtMonth: dates.previous,
      );
      expect(result.carriedBeforeMinor, 0);
      expect(result.adjustedLimitMinor, 50000);
    }
  });

  test('remaining days handle leap February and 31-day months', () {
    expect(day(date: DateTime(2028, 2, 28)).remainingDaysIncludingToday, 2);
    expect(day(date: DateTime(2027, 2, 28)).remainingDaysIncludingToday, 1);
    expect(day(date: DateTime(2026, 5, 1)).remainingDaysIncludingToday, 31);
  });

  test('editing or deleting an unsettled expense recalculates spending', () {
    expect(day(spent: 700).overspentMinor, 20000);
    expect(day(spent: 200).remainingMinor, 30000);
    final deleted = calculator.calculate(
      settings: settings,
      day: DateTime(2026, 4, 1),
      transactions: [],
    );
    expect(deleted.spentMinor, 0);
    expect(deleted.remainingMinor, 50000);
  });

  test('invalid inputs are rejected before producing a budget', () {
    expect(() => day(date: DateTime(2026, 3, 31)), throwsArgumentError);
    expect(() => day(debt: -1), throwsArgumentError);
    expect(() => day(debt: 100), throwsArgumentError);
    for (final amount in [-1.0, double.nan, double.infinity]) {
      expect(() => day(spent: amount), throwsArgumentError);
    }
    expect(
      () => calculator.settle(
        day: day(),
        walletBalanceMinor: -1,
        useWallet: true,
      ),
      throwsArgumentError,
    );
  });
}
