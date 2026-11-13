import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/money_account.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/screens/add_new_page.dart';
import 'package:expenz/widgets/home/funds_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 11, 13);
  const accounts = [
    MoneyAccount(id: 'cash', name: 'Cash in hand', openingBalanceMinor: 100000),
    MoneyAccount(
      id: 'bank1',
      name: 'Commercial Bank',
      openingBalanceMinor: 1000000,
    ),
    MoneyAccount(id: 'bank2', name: 'Sampath', openingBalanceMinor: 2000000),
    MoneyAccount(id: 'bank3', name: 'BOC', openingBalanceMinor: 3000000),
  ];
  final transactions = [
    TransactionModel(
      id: '1',
      title: 'Coffee',
      category: 'Food',
      amount: 100,
      date: now,
      type: TransactionType.expense,
    ),
    TransactionModel(
      id: '2',
      title: 'Shopping',
      category: 'Shopping',
      amount: 200,
      date: now,
      type: TransactionType.expense,
      accountId: 'bank1',
    ),
    TransactionModel(
      id: '3',
      title: 'Income',
      category: 'Salary',
      amount: 500,
      date: now,
      type: TransactionType.income,
      accountId: 'bank2',
    ),
    TransactionModel(
      id: '4',
      title: 'Yesterday',
      category: 'Food',
      amount: 50,
      date: now.subtract(const Duration(days: 1)),
      type: TransactionType.expense,
      accountId: 'cash',
    ),
  ];
  BudgetLedger ledger() => BudgetLedger(
    settings: null,
    accounts: accounts,
    transactions: transactions,
    settlements: [],
    walletEntries: [],
    readyForSettlement: true,
    hasPendingWrites: false,
    isFromCache: false,
  );

  test('three bank accounts and cash reconcile without double counting', () {
    expect(accounts[0].balanceMinor(transactions), 85000);
    expect(accounts[1].balanceMinor(transactions), 980000);
    expect(accounts[2].balanceMinor(transactions), 2050000);
    expect(accounts[3].balanceMinor(transactions), 3000000);
    expect(ledger().actualBalanceMinor, 6115000);
    expect(
      accounts.fold<int>(
        0,
        (sum, account) => sum + account.balanceMinor(transactions),
      ),
      ledger().actualBalanceMinor,
    );
  });

  test(
    'editing current funds preserves history and subsequent transactions',
    () {
      final updated = accounts[1].withCurrentBalance(500000, transactions);
      expect(updated.balanceMinor(transactions), 500000);
      final later = TransactionModel(
        id: 'later',
        title: 'Bus',
        category: 'Transport',
        amount: 100,
        date: now,
        type: TransactionType.expense,
        accountId: 'bank1',
      );
      expect(updated.balanceMinor([...transactions, later]), 490000);
      expect(transactions.length, 4);
    },
  );
  for (final size in [const Size(375, 812), const Size(812, 375)]) {
    testWidgets('funds cards show today only and summed bank funds at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FundsSummary(
                ledger: ledger(),
                today: now,
                onAccounts: () => opened = true,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Rs. 300'), findsOneWidget);
      expect(find.text('Rs. 850'), findsOneWidget);
      expect(find.text('Rs. 60,300'), findsOneWidget);

      await tester.ensureVisible(find.text('Bank balance'));
      await tester.tap(find.text('Bank balance'));
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('transaction preserves the selected bank account and date', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    TransactionModel? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: AddNewPage(
          initialAccounts: accounts,
          onSave: (value) async {
            saved = value;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, '250.25');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sampath').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Transport'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add expense'));
    await tester.pumpAndSettle();
    expect(saved!.accountId, 'bank2');
    expect(saved!.amount, 250.25);
    expect(DateUtils.isSameDay(saved!.date, DateTime.now()), isTrue);
  });
}
