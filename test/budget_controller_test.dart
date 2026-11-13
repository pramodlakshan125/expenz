import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/models/wallet_entry.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_budget_repository.dart';

void main() {
  late FakeBudgetRepository repository;
  late BudgetController controller;
  var now = DateTime(2026, 4, 2);
  final settings = DailyBudgetSettings(
    dailyLimitMinor: 50000,
    startDate: DateTime(2026, 4, 1),
  );

  BudgetLedger ledger({
    bool ready = true,
    bool pending = false,
    DailyBudgetSettings? budget,
    List<DailySettlement> settlements = const [],
    List<WalletEntry> wallet = const [],
    List<TransactionModel> transactions = const [],
  }) => BudgetLedger(
    settings: budget ?? settings,
    transactions: transactions,
    settlements: settlements,
    walletEntries: wallet,
    readyForSettlement: ready,
    hasPendingWrites: pending,
    isFromCache: true,
  );

  setUp(() {
    now = DateTime(2026, 4, 2);
    repository = FakeBudgetRepository();
    controller = BudgetController(repository: repository, clock: () => now)
      ..start();
  });
  tearDown(() async {
    controller.dispose();
    await repository.events.close();
  });

  test('repeated taps cannot queue the same settlement twice', () {
    repository.events.add(ledger());
    controller.settleNext(expectedDayKey: '2026-04-01', useWallet: true);
    expect(repository.savedDays.single.walletChangeMinor, 50000);
    expect(controller.saving, isTrue);
    expect(
      () =>
          controller.settleNext(expectedDayKey: '2026-04-01', useWallet: true),
      throwsStateError,
    );
    expect(repository.savedDays.length, 1);
  });

  test(
    'a local pending batch unlocks the next action without a server ack',
    () {
      repository.events.add(ledger());
      controller.settleNext(expectedDayKey: '2026-04-01', useWallet: true);
      final saved = repository.savedDays.single;
      repository.events.add(
        ledger(
          pending: true,
          settlements: [saved],
          wallet: [
            WalletEntry(
              relatedDay: saved.dayKey,
              date: saved.date,
              amountMinor: 50000,
              type: WalletEntryType.deposit,
            ),
          ],
        ),
      );
      expect(controller.saving, isFalse);
      expect(controller.plan!.unsettledCount, 0);
      expect(controller.ledger!.hasPendingWrites, isTrue);
      expect(controller.ledger!.walletBalanceMinor, 50000);
      expect(controller.ledger!.actualBalanceMinor, 0);
      expect(
        () => controller.settleNext(
          expectedDayKey: saved.dayKey,
          useWallet: true,
        ),
        throwsStateError,
      );
    },
  );

  test('first-time incomplete cache cannot close a day', () {
    repository.events.add(ledger(ready: false));
    expect(controller.canAct, isFalse);
    expect(
      () =>
          controller.settleNext(expectedDayKey: '2026-04-01', useWallet: true),
      throwsStateError,
    );
    expect(repository.savedDays, isEmpty);
  });

  test('closed history is required before changing the daily target', () {
    repository.events.add(ledger());
    expect(() => controller.setLimit(60000), throwsStateError);
    expect(repository.savedSettings, isEmpty);
  });

  test('target changes preserve setup date and wait only for local echo', () {
    now = DateTime(2026, 4, 1);
    repository.events.add(ledger());
    controller.setLimit(60000);
    expect(repository.savedSettings.single.startDate, settings.startDate);
    expect(controller.saving, isTrue);
    repository.events.add(
      ledger(budget: repository.savedSettings.single, pending: true),
    );
    expect(controller.saving, isFalse);
    expect(controller.plan!.today.adjustedLimitMinor, 60000);
  });

  test('a rejected write releases the lock and surfaces the failure', () {
    repository.events.add(ledger());
    controller.settleNext(expectedDayKey: '2026-04-01', useWallet: true);
    repository.rejectLastWrite!(StateError('permission denied'));
    expect(controller.error, isA<StateError>());
    expect(controller.saving, isFalse);
    expect(controller.canAct, isFalse);
    repository.events.add(ledger()); // Firestore rollback snapshot.
    expect(controller.canAct, isTrue);
    expect(controller.plan!.unsettledCount, 1);
  });

  test(
    'refresh after midnight exposes the completed day, never closes today',
    () {
      now = DateTime(2026, 4, 1, 23, 59);
      repository.events.add(ledger());
      expect(controller.plan!.nextUnsettledDay, isNull);
      now = DateTime(2026, 4, 2);
      controller.refresh();
      expect(controller.plan!.nextUnsettledDay!.date, DateTime(2026, 4, 1));
      expect(controller.plan!.today.date, DateTime(2026, 4, 2));
    },
  );
}
