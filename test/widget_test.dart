import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/screens/add_new_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    Future<void> Function(TransactionModel) save, {
    TransactionType type = TransactionType.expense,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddNewPage(initialType: type, onSave: save),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rejects zero and saves an expense once with its note', (
    tester,
  ) async {
    final saved = <TransactionModel>[];
    await open(tester, (transaction) async {
      saved.add(transaction);
    });
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '10000');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining'));
    await tester.enterText(find.byType(TextField), 'Lunch with team');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction saved'), findsOneWidget);
    expect(saved.length, 1);
    expect(saved.single.amount, 10000);
    expect(saved.single.type, TransactionType.expense);
    expect(saved.single.title, 'Lunch with team');
    await tester.tap(find.text('Add another transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Enter amount'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('income shows income categories and saves a positive amount', (
    tester,
  ) async {
    TransactionModel? saved;
    await open(tester, (transaction) async {
      saved = transaction;
    }, type: TransactionType.income);
    await tester.enterText(find.byType(TextField), '45000.50');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Food & Dining'), findsNothing);
    await tester.tap(find.text('Salary'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(saved!.isIncome, isTrue);
    expect(saved!.amount, 45000.50);
    expect(find.text('Transaction saved'), findsOneWidget);
  });

  testWidgets('failed saves retain input and allow retry', (tester) async {
    var attempts = 0;
    await open(tester, (_) async {
      if (attempts++ == 0) throw Exception('offline');
    });
    await tester.enterText(find.byType(TextField), '1200');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transport'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction saved'), findsNothing);
    expect(
      find.text('Could not save. Check your connection and try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction saved'), findsOneWidget);
    expect(attempts, 2);
  });
}
