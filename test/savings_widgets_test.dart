import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/goal_contribution.dart';
import 'package:expenz/models/savings_goal.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/models/wallet_entry.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/widgets/goals/goals_section.dart';
import 'package:expenz/widgets/home/savings_transfer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_budget_repository.dart';

void main() {
  final now = DateTime(2026, 11, 12);
  final goal = SavingsGoal(
    id: 'holiday',
    title: 'Holiday',
    targetMinor: 500000,
    initialSavedMinor: 100000,
    createdAt: now,
  );
  final deposit = WalletEntry(
    id: 'topup-1-0-1',
    relatedDay: '2026-11-12',
    date: now,
    amountMinor: 200000,
    type: WalletEntryType.deposit,
    source: WalletEntrySource.manualTopUp,
  );
  BudgetLedger ledger({
    List<WalletEntry>? entries,
    List<GoalContribution> contributions = const [],
  }) => BudgetLedger(
    settings: null,
    transactions: [
      TransactionModel(
        id: 'income',
        title: 'Salary',
        category: 'Salary',
        amount: 10000,
        date: now,
        type: TransactionType.income,
      ),
    ],
    settlements: [],
    walletEntries: entries ?? [deposit],
    goals: [goal],
    goalContributions: contributions,
    readyForSettlement: true,
    hasPendingWrites: false,
    isFromCache: true,
  );

  testWidgets(
    'manual top-up checks available funds then queues the entered amount',
    (tester) async {
      final repository = FakeBudgetRepository();
      final controller = BudgetController(
        repository: repository,
        clock: () => now,
      )..start();
      repository.events.add(ledger());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SavingsTransferSheet(controller: controller),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Available to set aside: Rs. 7,000'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '7000.01');
      await tester.tap(find.widgetWithText(FilledButton, 'Add to wallet'));
      await tester.pump();
      expect(find.text('Enter no more than Rs. 7,000.'), findsOneWidget);
      expect(repository.savedTransfers, isEmpty);
      await tester.enterText(find.byType(TextFormField), '1000.25');
      await tester.tap(find.widgetWithText(FilledButton, 'Add to wallet'));
      await tester.pumpAndSettle();
      expect(repository.savedTransfers.single.amountMinor, 100025);
      expect(
        repository.savedTransfers.single.source,
        WalletEntrySource.manualTopUp,
      );
      expect(find.byType(TextFormField), findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await repository.events.close();
    },
  );

  testWidgets(
    'goal transfer preselects a goal and rejects more than wallet holds',
    (tester) async {
      final repository = FakeBudgetRepository();
      final controller = BudgetController(
        repository: repository,
        clock: () => now,
      )..start();
      repository.events.add(ledger());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SavingsTransferSheet(
                controller: controller,
                toGoal: true,
                initialGoalId: goal.id,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Wallet balance: Rs. 2,000'), findsOneWidget);
      expect(find.text('Rs. 4,000 left to reach this goal.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).last, '2000.01');
      await tester.tap(find.widgetWithText(FilledButton, 'Transfer to goal'));
      await tester.pump();
      expect(find.text('Enter no more than Rs. 2,000.'), findsOneWidget);
      expect(repository.savedTransfers, isEmpty);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await repository.events.close();
    },
  );

  testWidgets('goals display linked contributions and expose Add from wallet', (
    tester,
  ) async {
    final repository = FakeBudgetRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalsSection(repository: repository),
          ),
        ),
      ),
    );
    repository.events.add(ledger());
    await tester.pump();
    expect(find.text('Rs. 1,000 of Rs. 5,000'), findsOneWidget);
    expect(find.text('Add from wallet'), findsOneWidget);
    final transfer = WalletEntry(
      id: 'goal-1-0-1',
      relatedDay: '2026-11-12',
      date: now,
      amountMinor: 50000,
      type: WalletEntryType.withdraw,
      source: WalletEntrySource.goalTransfer,
      goalId: goal.id,
    );
    repository.events.add(
      ledger(
        entries: [deposit, transfer],
        contributions: [
          GoalContribution(
            id: transfer.id,
            goalId: goal.id,
            amountMinor: 50000,
            date: now,
          ),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Rs. 1,500 of Rs. 5,000'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await repository.events.close();
  });

  testWidgets('new goal uses the queued service and starts with zero savings', (
    tester,
  ) async {
    final repository = FakeBudgetRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GoalsSection(repository: repository),
          ),
        ),
      ),
    );
    repository.events.add(ledger());
    await tester.pump();
    await tester.tap(find.text('New goal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Goal name'),
      'Laptop',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Target amount'),
      '25000',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create goal'));
    await tester.pumpAndSettle();
    expect(repository.savedGoals.single.title, 'Laptop');
    expect(repository.savedGoals.single.targetMinor, 2500000);
    expect(repository.savedGoals.single.initialSavedMinor, 0);
    await tester.pumpWidget(const SizedBox());
    await repository.events.close();
  });
}
