import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/screens/spending_trends.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('handles no spending without invalid averages', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SpendingTrends(transactions: [])),
    );
    expect(find.text('Rs. 0'), findsOneWidget);
    expect(find.text('No expenses in the last 12 months.'), findsOneWidget);
    expect(find.text('Highest month'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly average excludes income and older expenses', (
    tester,
  ) async {
    final now = DateTime.now();
    TransactionModel transaction(
      String id,
      double amount,
      DateTime date,
      TransactionType type,
    ) => TransactionModel(
      id: id,
      title: id,
      category: 'Food',
      amount: amount,
      date: date,
      type: type,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SpendingTrends(
          transactions: [
            transaction('expense', 1200, now, TransactionType.expense),
            transaction('income', 2400, now, TransactionType.income),
            transaction(
              'old',
              3600,
              DateTime(now.year - 2),
              TransactionType.expense,
            ),
          ],
        ),
      ),
    );
    expect(find.text('Rs. 100'), findsOneWidget);
    expect(find.text('Highest month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
