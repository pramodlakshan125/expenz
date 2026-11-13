import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/goal_contribution.dart';
import 'package:expenz/models/savings_goal.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/models/wallet_entry.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/services/budget_firestore_codec.dart';
import 'package:expenz/services/savings_transfer_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_budget_repository.dart';

void main() {
  final now = DateTime(2026, 11, 12, 10);
  final goal = SavingsGoal(
    id: 'laptop',
    title: 'Laptop',
    targetMinor: 500000,
    initialSavedMinor: 100000,
    createdAt: now,
  );
  final existing = WalletEntry(
    id: 'topup-1-0-1',
    relatedDay: '2026-11-12',
    date: now,
    amountMinor: 200000,
    type: WalletEntryType.deposit,
    source: WalletEntrySource.manualTopUp,
  );
  final income = TransactionModel(
    id: 'income',
    title: 'Salary',
    category: 'Salary',
    amount: 10000,
    date: now,
    type: TransactionType.income,
  );
  BudgetLedger ledger({
    List<WalletEntry>? entries,
    List<GoalContribution> contributions = const [],
    bool ready = true,
    bool pending = false,
  }) => BudgetLedger(
    settings: null,
    transactions: [income],
    settlements: [],
    walletEntries: entries ?? [existing],
    goals: [goal],
    goalContributions: contributions,
    readyForSettlement: ready,
    hasPendingWrites: pending,
    isFromCache: true,
  );
  const calculator = SavingsTransferCalculator();

  test('manual top-up reserves existing funds without adding income', () {
    final before = ledger();
    expect(before.availableToSaveMinor, 700000);
    final topUp = calculator.topUp(
      ledger: before,
      amountMinor: 700000,
      id: 'topup-2-0-1',
      now: now,
    );
    final after = ledger(entries: [existing, topUp]);
    expect(after.walletBalanceMinor, 900000);
    expect(after.actualBalanceMinor, before.actualBalanceMinor);
    expect(after.availableToSaveMinor, 0);
    expect(after.transactions.length, 1);
  });

  test(
    'goal allocations are excluded from money available for another top-up',
    () {
      final contribution = GoalContribution(
        id: 'goal-1-0-1',
        goalId: goal.id,
        amountMinor: 50000,
        date: now,
      );
      expect(
        ledger(contributions: [contribution]).availableToSaveMinor,
        650000,
      );
      expect(
        () => calculator.topUp(
          ledger: ledger(contributions: [contribution]),
          amountMinor: 650001,
          id: 'topup-2-0-1',
          now: now,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'wallet-to-goal transfer preserves total savings and bank plus cash',
    () {
      final before = ledger();
      final entry = calculator.toGoal(
        ledger: before,
        amountMinor: 50000,
        goalId: goal.id,
        id: 'goal-2-0-1',
        now: now,
      );
      final after = ledger(
        entries: [existing, entry],
        contributions: [
          GoalContribution(
            id: entry.id,
            goalId: goal.id,
            amountMinor: 50000,
            date: now,
          ),
        ],
      );
      expect(after.walletBalanceMinor, 150000);
      expect(after.goalSavedMinor(goal), 150000);
      expect(
        after.walletBalanceMinor + after.goalReservedMinor,
        before.walletBalanceMinor + before.goalReservedMinor,
      );
      expect(after.actualBalanceMinor, before.actualBalanceMinor);
      expect(after.availableToSaveMinor, before.availableToSaveMinor);
    },
  );

  test(
    'rejects insufficient wallet, unknown goal, and over-target transfers',
    () {
      expect(
        () => calculator.toGoal(
          ledger: ledger(),
          amountMinor: 200001,
          goalId: goal.id,
          id: 'goal-2-0-1',
          now: now,
        ),
        throwsStateError,
      );
      expect(
        () => calculator.toGoal(
          ledger: ledger(),
          amountMinor: 100,
          goalId: 'deleted',
          id: 'goal-2-0-1',
          now: now,
        ),
        throwsStateError,
      );
      final nearlyComplete = ledger(
        contributions: [
          GoalContribution(
            id: 'old',
            goalId: goal.id,
            amountMinor: 399999,
            date: now,
          ),
        ],
      );
      expect(
        () => calculator.toGoal(
          ledger: nearlyComplete,
          amountMinor: 2,
          goalId: goal.id,
          id: 'goal-2-0-1',
          now: now,
        ),
        throwsStateError,
      );
      for (final amount in [0, -1]) {
        expect(
          () => calculator.topUp(
            ledger: ledger(),
            amountMinor: amount,
            id: 'topup-2-0-1',
            now: now,
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test('new wallet and paired contribution maps round-trip exact cents', () {
    final transfer = calculator.toGoal(
      ledger: ledger(),
      amountMinor: 12345,
      goalId: goal.id,
      id: 'goal-2-0-1',
      now: now,
    );
    final restored = BudgetFirestoreCodec.wallet(
      transfer.id,
      BudgetFirestoreCodec.transferData(transfer),
    );
    final contribution = BudgetFirestoreCodec.contribution(
      transfer.id,
      BudgetFirestoreCodec.contributionData(transfer),
    );
    expect(restored.source, WalletEntrySource.goalTransfer);
    expect(restored.goalId, goal.id);
    expect(restored.signedAmountMinor, -12345);
    expect(contribution.amountMinor, 12345);
    expect(contribution.date.isAtSameMomentAs(restored.date), isTrue);
    final data = BudgetFirestoreCodec.contributionData(transfer);
    expect(
      () => BudgetFirestoreCodec.contribution(transfer.id, {
        ...data,
        'walletEntryId': 'wrong',
      }),
      throwsFormatException,
    );
  });

  test(
    'controller blocks repeated top-up taps until local write echo',
    () async {
      final repository = FakeBudgetRepository();
      final controller = BudgetController(
        repository: repository,
        clock: () => now,
      )..start();
      repository.events.add(ledger());
      controller.addToWallet(10000);
      expect(controller.saving, isTrue);
      expect(() => controller.addToWallet(10000), throwsStateError);
      final entry = repository.savedTransfers.single;
      repository.events.add(ledger(entries: [existing, entry], pending: true));
      expect(controller.saving, isFalse);
      expect(controller.canAct, isTrue);
      expect(controller.ledger!.walletBalanceMinor, 210000);
      controller.dispose();
      await repository.events.close();
    },
  );

  test(
    'controller queues paired goal transfer offline and surfaces rejection',
    () async {
      final repository = FakeBudgetRepository();
      final controller = BudgetController(
        repository: repository,
        clock: () => now,
      )..start();
      repository.events.add(ledger());
      controller.transferToGoal(goalId: goal.id, amountMinor: 50000);
      expect(
        repository.savedTransfers.single.source,
        WalletEntrySource.goalTransfer,
      );
      expect(
        () => controller.transferToGoal(goalId: goal.id, amountMinor: 1),
        throwsStateError,
      );
      repository.rejectLastWrite!(StateError('rejected'));
      expect(controller.error, isA<StateError>());
      expect(controller.saving, isFalse);
      controller.dispose();
      await repository.events.close();
    },
  );

  test(
    'goal creation queues locally without requiring a daily target',
    () async {
      final repository = FakeBudgetRepository();
      final controller = BudgetController(
        repository: repository,
        clock: () => now,
      )..start();
      repository.events.add(ledger());
      controller.createGoal(title: '  Holiday  ', targetMinor: 250000);
      expect(repository.savedGoals.single.title, 'Holiday');
      expect(repository.savedGoals.single.initialSavedMinor, 0);
      expect(controller.saving, isTrue);
      controller.dispose();
      await repository.events.close();
    },
  );
}
