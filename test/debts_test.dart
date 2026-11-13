import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/debt_account.dart';
import 'package:expenz/models/money_account.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/services/daily_budget_calculator.dart';
import 'package:expenz/services/budget_controller.dart';
import 'support/fake_budget_repository.dart';
import 'package:expenz/widgets/home/funds_summary.dart';
import 'package:expenz/widgets/home/debts_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateUtils.dateOnly(DateTime.now());
  const cash = MoneyAccount(
    id: 'cash',
    name: 'Cash in hand',
    openingBalanceMinor: 100000,
  );
  const bank = MoneyAccount(
    id: 'bank',
    name: 'Bank',
    openingBalanceMinor: 500000,
  );
  DebtAccount debt(String id, DebtKind kind, int principal, int repaid) =>
      DebtAccount(
        id: id,
        name: id,
        kind: kind,
        principalMinor: principal,
        repaidMinor: repaid,
        createdAt: now,
        lastEntryId: id,
      );
  DebtEntry entry(
    String id,
    String debtId,
    DebtKind kind,
    DebtAction action,
    int amount, {
    String accountId = 'bank',
    bool movesCash = true,
  }) => DebtEntry(
    id: id,
    debtId: debtId,
    kind: kind,
    action: action,
    amountMinor: amount,
    accountId: accountId,
    movesCash: movesCash,
    date: now,
  );
  final loans = [
    debt('friend', DebtKind.receivable, 100000, 40000),
    debt('borrowed', DebtKind.payable, 200000, 50000),
    debt('card', DebtKind.creditCard, 120000, 30000),
  ];
  final entries = [
    entry('lent', 'friend', DebtKind.receivable, DebtAction.opening, 100000),
    entry(
      'received',
      'friend',
      DebtKind.receivable,
      DebtAction.repayment,
      40000,
    ),
    entry('borrowed', 'borrowed', DebtKind.payable, DebtAction.opening, 200000),
    entry('repaid', 'borrowed', DebtKind.payable, DebtAction.repayment, 50000),
    entry(
      'card',
      'card',
      DebtKind.creditCard,
      DebtAction.opening,
      100000,
      movesCash: false,
    ),
    entry(
      'charge',
      'card',
      DebtKind.creditCard,
      DebtAction.charge,
      20000,
      accountId: 'credit:card',
      movesCash: false,
    ),
    entry(
      'card-payment',
      'card',
      DebtKind.creditCard,
      DebtAction.repayment,
      30000,
      accountId: 'cash',
    ),
  ];
  final purchase = TransactionModel(
    id: 'charge',
    title: 'Card purchase',
    category: 'Credit card purchase',
    amount: 200,
    date: now,
    type: TransactionType.expense,
    accountId: 'credit:card',
  );
  BudgetLedger ledger() => BudgetLedger(
    settings: null,
    accounts: [cash, bank],
    transactions: [purchase],
    debts: loans,
    debtEntries: entries,
    settlements: [],
    walletEntries: [],
    readyForSettlement: true,
    hasPendingWrites: false,
    isFromCache: false,
  );

  test('loan cash flows and repayments do not become income or expenses', () {
    final value = ledger();
    expect(bank.balanceMinor(value.transactions, debtEntries: entries), 590000);
    expect(cash.balanceMinor(value.transactions, debtEntries: entries), 70000);
    expect(value.actualBalanceMinor, 660000);
    expect(value.debtBalanceMinor(DebtKind.receivable), 60000);
    expect(value.debtBalanceMinor(DebtKind.payable), 150000);
    expect(value.debtBalanceMinor(DebtKind.creditCard), 90000);
    expect(
      value.transactions.where((transaction) => transaction.isIncome),
      isEmpty,
    );
    final today = const DailyBudgetCalculator().calculate(
      settings: DailyBudgetSettings(dailyLimitMinor: 100000, startDate: now),
      day: now,
      transactions: value.transactions,
    );
    expect(today.spentMinor, 20000);
    expect(purchase.cashChangeMinor, 0);
  });

  test(
    'historical debts have no cash effect and balance correction includes loan flows',
    () {
      final historical = entry(
        'old',
        'old',
        DebtKind.receivable,
        DebtAction.opening,
        200000,
        movesCash: false,
      );
      expect(historical.cashChangeMinor, 0);
      final corrected = bank.withCurrentBalance(500000, [
        purchase,
      ], debtEntries: entries);
      expect(
        corrected.balanceMinor(
          [purchase],
          debtEntries: [...entries, historical],
        ),
        500000,
      );
    },
  );

  testWidgets(
    'all six compact cards scroll and debt totals open the matching panel',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      DebtKind? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SingleChildScrollView(
                child: FundsSummary(
                  ledger: ledger(),
                  today: now,
                  onDebts: (kind) => opened = kind,
                ),
              ),
            ),
          ),
        ),
      );
      for (final kind in DebtKind.values) {
        await tester.ensureVisible(find.text(kind.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(kind.label));
        expect(opened, kind);
      }
      expect(tester.takeException(), isNull);
    },
  );

  Future<void> openEditor(
    WidgetTester tester, {
    DebtKind kind = DebtKind.receivable,
    DebtAccount? existing,
    bool charge = false,
    required Future<void> Function(DebtDraft) save,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DebtEditor(
                  ledger: ledger(),
                  kind: kind,
                  debt: existing,
                  charge: charge,
                  onSave: save,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('an existing debt can be recorded without moving cash', (
    tester,
  ) async {
    DebtDraft? saved;
    await openEditor(
      tester,
      save: (draft) async {
        saved = draft;
      },
    );
    await tester.enterText(find.byType(TextFormField).first, 'Friend');
    await tester.enterText(find.byType(TextFormField).last, '1200.25');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(saved!.amountMinor, 120025);
    expect(saved!.movesCash, isFalse);
    expect(saved!.name, 'Friend');
  });

  testWidgets(
    'repayments reject overpayment and retain input after a failed save',
    (tester) async {
      var attempts = 0;
      await openEditor(
        tester,
        kind: DebtKind.payable,
        existing: loans[1],
        save: (_) async {
          attempts++;
          throw StateError('Try again');
        },
      );
      await tester.enterText(find.byType(TextFormField), '1500.01');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Pay'));
      await tester.tap(find.widgetWithText(FilledButton, 'Pay'));
      await tester.pumpAndSettle();
      expect(find.text('Enter no more than Rs. 1,500.'), findsOneWidget);
      expect(attempts, 0);
      await tester.enterText(find.byType(TextFormField), '500');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Pay'));
      await tester.tap(find.widgetWithText(FilledButton, 'Pay'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '500',
      );
      expect(attempts, 1);
    },
  );

  testWidgets('credit opening and purchases never choose a cash account', (
    tester,
  ) async {
    await openEditor(tester, kind: DebtKind.creditCard, save: (_) async {});
    expect(find.text('Amount currently owed'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await openEditor(
      tester,
      kind: DebtKind.creditCard,
      existing: loans[2],
      charge: true,
      save: (_) async {},
    );
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Add purchase / fee'), findsOneWidget);
  });
  testWidgets('a new credit card may start with no outstanding balance', (
    tester,
  ) async {
    DebtDraft? saved;
    await openEditor(
      tester,
      kind: DebtKind.creditCard,
      save: (draft) async {
        saved = draft;
      },
    );
    await tester.enterText(find.byType(TextFormField).first, 'My card');
    await tester.enterText(find.byType(TextFormField).last, '0');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(saved!.amountMinor, 0);
    expect(saved!.movesCash, isFalse);
  });
  testWidgets('tapping a person opens Pay with cash and bank choices', (
    tester,
  ) async {
    final repository = FakeBudgetRepository();
    final controller = BudgetController(repository: repository)..start();
    repository.events.add(ledger());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebtsSheet(controller: controller, kind: DebtKind.payable),
        ),
      ),
    );
    await tester.tap(find.text('borrowed'));
    await tester.pumpAndSettle();
    expect(find.byType(DebtEditor), findsOneWidget);
    expect(find.text('Record payment'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Pay'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '1500.00',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Cash in hand'), findsWidgets);
    expect(find.text('Bank'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await repository.events.close();
  });

  testWidgets('Pay submits the selected bank and partial amount', (
    tester,
  ) async {
    DebtDraft? saved;
    await openEditor(
      tester,
      kind: DebtKind.payable,
      existing: loans[1],
      save: (draft) async {
        saved = draft;
      },
    );
    await tester.enterText(find.byType(TextFormField), '500');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Pay'));
    await tester.tap(find.widgetWithText(FilledButton, 'Pay'));
    await tester.pumpAndSettle();
    expect(saved!.accountId, 'bank');
    expect(saved!.amountMinor, 50000);
  });
}
