import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/widgets/home/recent_transactions.dart';
import 'package:expenz/widgets/home/quick_actions_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recent preview shows only four newest transactions and opens history', (tester) async {
    var opened = false;
    final items = List.generate(6, (i) => TransactionModel(id: '$i', title: 'Item $i', category: 'Food', amount: 100, date: DateTime(2026, 1, i + 1), type: TransactionType.expense));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: RecentTransactions(transactions: items, onSeeAll: () => opened = true)))));
    expect(find.text('Item 5'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 1'), findsNothing);
    expect(find.text('Item 0'), findsNothing);
    await tester.tap(find.text('See more'));
    expect(opened, isTrue);
  });

  testWidgets('goals and insights shortcuts invoke their destinations', (tester) async {
    var goals = false;
    var insights = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: QuickActionsRow(onGoals: () => goals = true, onInsights: () => insights = true))));
    await tester.tap(find.byIcon(Icons.flag_rounded));
    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    expect(goals, isTrue);
    expect(insights, isTrue);
  });
}
