import 'package:expenz/constant/colors.dart';
import 'package:expenz/data/dummy_transactions.dart';
import 'package:expenz/widgets/home/balance_card.dart';
import 'package:expenz/widgets/home/home_header.dart';
import 'package:expenz/widgets/home/quick_actions_row.dart';
import 'package:expenz/widgets/home/recent_transactions.dart';
import 'package:flutter/material.dart';

/// The Home tab. It only places the pieces.
/// Each piece lives in its own file in widgets/home/.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spentThisMonth = DummyTransactions.list
        .where(
          (transaction) =>
              !transaction.isIncome &&
              transaction.date.year == now.year &&
              transaction.date.month == now.month,
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Step 4: header
            const HomeHeader(userName: 'Pramod', hasNotification: true),
            const SizedBox(height: 24),

            BalanceCard(spentAmount: spentThisMonth, monthlyBudget: 500000),
            const SizedBox(height: 24),

            // Step 6: quick actions
            const QuickActionsRow(),
            const SizedBox(height: 24),

            // Step 8: recent transactions (fake data for now)
            RecentTransactions(
              transactions: DummyTransactions.list,
              onSeeAll: () {},
            ),
          ],
        ),
      ),
    );
  }
}
