import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/services/balance_reconciliation.dart';
import 'package:expenz/formatters/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BalanceReconciliation();
  test('a lower bank plus cash total creates an unrecorded expense', () {
    final value = service.adjustment(
      recordedBalanceMinor: 1000000,
      bankMinor: 800000,
      cashMinor: 100000,
      now: DateTime(2026, 4, 2),
      id: 'correction',
    )!;
    expect(value.amount, 1000);
    expect(value.type, TransactionType.expense);
    expect(value.title, 'Unrecorded expense');
    expect(value.date, DateTime(2026, 4, 2));
  });
  test('a higher total creates adjustment income; matching needs no entry', () {
    final value = service.adjustment(
      recordedBalanceMinor: 1000000,
      bankMinor: 1000000,
      cashMinor: 100000,
      now: DateTime(2026, 4, 2),
      id: 'correction',
    )!;
    expect(value.amount, 1000);
    expect(value.type, TransactionType.income);
    expect(
      service.adjustment(
        recordedBalanceMinor: 100,
        bankMinor: 50,
        cashMinor: 50,
        now: DateTime(2026),
        id: 'same',
      ),
      isNull,
    );
  });
  test('rejects negative real balances', () {
    expect(
      () => service.adjustment(
        recordedBalanceMinor: 0,
        bankMinor: -1,
        cashMinor: 0,
        now: DateTime(2026),
        id: 'bad',
      ),
      throwsArgumentError,
    );
  });
  test('money input keeps exact cents and rejects malformed amounts', () {
    expect(parseMoneyMinor('500'), 50000);
    expect(parseMoneyMinor('0.01'), 1);
    expect(parseMoneyMinor('123.45'), 12345);
    for (final input in ['', '-1', 'NaN', 'Infinity', '1.001', '1e10']) {
      expect(parseMoneyMinor(input), isNull);
    }
  });
}
