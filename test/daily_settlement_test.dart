import 'package:expenz/models/daily_settlement.dart';
import 'package:expenz/services/budget_firestore_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DailySettlement settlement({
    int spent = 65000,
    int change = -5000,
    SettlementAction action = SettlementAction.coveredByWallet,
  }) => DailySettlement(
    date: DateTime(2026, 4, 3, 15),
    baseLimitMinor: 50000,
    adjustedLimitMinor: 49310,
    spentMinor: spent,
    action: action,
    walletChangeMinor: change,
    carriedBeforeMinor: 19310,
    carryAssignedMinor: 690,
  );

  test(
    'settlement preserves partial coverage and outstanding earlier debt',
    () {
      final value = settlement();
      expect(value.dayKey, '2026-04-03');
      expect(value.date, DateTime(2026, 4, 3));
      expect(value.leftoverMinor, 0);
      expect(value.overspentMinor, 15690);
      expect(value.uncoveredMinor, 10690);
      expect(value.carriedAfterMinor, 29310);
    },
  );

  test('saved model and wallet entry survive a Firestore map round trip', () {
    final value = settlement();
    final restored = BudgetFirestoreCodec.settlement(
      value.dayKey,
      BudgetFirestoreCodec.settlementData(value),
    );
    final entry = BudgetFirestoreCodec.wallet(
      value.dayKey,
      BudgetFirestoreCodec.walletData(value),
    );
    expect(restored.carriedAfterMinor, value.carriedAfterMinor);
    expect(restored.walletChangeMinor, -5000);
    expect(entry.signedAmountMinor, -5000);
    expect(entry.relatedDay, value.dayKey);
  });

  test('rejects invalid actions and more wallet coverage than overspend', () {
    expect(() => settlement(change: -20000), throwsArgumentError);
    expect(
      () => settlement(change: 100, action: SettlementAction.savedToWallet),
      throwsArgumentError,
    );
    expect(
      () => settlement(change: 0, action: SettlementAction.none),
      throwsArgumentError,
    );
    expect(() => settlement(spent: -1), throwsArgumentError);
  });

  test('rejects malformed dates, IDs and inconsistent saved totals', () {
    final value = settlement();
    final data = BudgetFirestoreCodec.settlementData(value);
    expect(
      () => BudgetFirestoreCodec.settlement('2026-04-04', data),
      throwsFormatException,
    );
    expect(
      () => BudgetFirestoreCodec.settlement(value.dayKey, {
        ...data,
        'uncovered': 1,
      }),
      throwsFormatException,
    );
    expect(
      () => BudgetFirestoreCodec.calendarDate('2026-02-30'),
      throwsFormatException,
    );
    expect(
      () => BudgetFirestoreCodec.calendarDate('2026-4-3'),
      throwsFormatException,
    );
  });
}
