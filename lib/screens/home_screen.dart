import 'package:expenz/screens/goals_page.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/widgets/home/balance_card.dart';
import 'package:expenz/widgets/home/home_header.dart';
import 'package:expenz/widgets/home/quick_actions_row.dart';
import 'package:expenz/widgets/home/recent_transactions.dart';
import 'package:flutter/material.dart';

/// The Home tab. It only places the pieces.
/// Each piece lives in its own file in widgets/home/.
class HomeScreen extends StatelessWidget {
  final String userName;
  final List<TransactionModel> transactions;
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;
  final VoidCallback? onSeeAll;
  final VoidCallback? onGoals;
  final VoidCallback? onInsights;
  const HomeScreen({
    super.key,
    this.userName = '',
    this.transactions = const [],
    this.onAddExpense,
    this.onAddIncome,
    this.onSeeAll,
    this.onGoals,
    this.onInsights,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spentThisMonth = transactions
        .where(
          (transaction) =>
              !transaction.isIncome &&
              transaction.date.year == now.year &&
              transaction.date.month == now.month,
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Step 4: header
            HomeHeader(userName: userName, hasNotification: true),
            SizedBox(height: 24),

            BalanceCard(spentAmount: spentThisMonth, monthlyBudget: 500000),
            SizedBox(height: 24),

            // Step 6: quick actions
            QuickActionsRow(
              onAddExpense: onAddExpense,
              onAddIncome: onAddIncome,
              onGoals: onGoals,
              onInsights: onInsights,
            ),
            SizedBox(height: 24),

            // Recent saved transactions
            RecentTransactions(
              transactions: transactions,
              maxItems: 4,
              onSeeAll: onSeeAll,
            ),
            SizedBox(height: 24),
            GoalsSection(preview: true, onSeeMore: onGoals),
          ],
        ),
      ),
    );
  }
}
