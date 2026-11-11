import 'package:expenz/constant/app_icons.dart';
import 'package:expenz/widgets/home/quick_action_item.dart';
import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback? onAddExpense;
  final VoidCallback? onAddIncome;
  final VoidCallback? onBills;
  final VoidCallback? onSavings;
  final VoidCallback? onGoals;
  final VoidCallback? onInsights;

  const QuickActionsRow({
    super.key,
    this.onAddExpense,
    this.onAddIncome,
    this.onBills,
    this.onSavings,
    this.onGoals,
    this.onInsights,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionItem(
              icon: AppIcons.plus,
              label: 'Add Expense',
              onTap: onAddExpense,
            ),
            QuickActionItem(
              icon: AppIcons.income,
              label: 'Add Income',
              onTap: onAddIncome,
            ),
            QuickActionItem(
              icon: Icons.bar_chart_rounded,
              color: Color(0xFF3C4C52),
              label: 'Insights',
              onTap: onInsights,
            ),
            QuickActionItem(
              icon: Icons.flag_rounded,
              label: 'Goals',
              onTap: onGoals,
            ),
          ],
        ),
      ],
    );
  }
}
