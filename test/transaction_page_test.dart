import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/screens/transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('search and type filters combine and can be cleared', (tester) async {
    final now = DateTime.now();
    final transactions = [
      TransactionModel(id: '1', title: 'Coffee', category: 'Food', amount: 350, date: now, type: TransactionType.expense),
      TransactionModel(id: '2', title: 'Salary', category: 'Income', amount: 45000, date: now, type: TransactionType.income),
    ];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TransactionPage(transactions: transactions))));
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'FOOD');
    await tester.pump();
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);
    expect(find.text('1 results'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Income'));
    await tester.pump();
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('No matching transactions. Try another search or filter.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Coffee'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and errors do not show misleading totals', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TransactionPage(loading: true))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Money in'), findsNothing);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TransactionPage(hasError: true))));
    expect(find.text('Could not load transactions. Check your connection.'), findsOneWidget);
    expect(find.textContaining('Money in'), findsNothing);
  });
}
