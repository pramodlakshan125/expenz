import 'package:expenz/constant/colors.dart';
import 'package:expenz/formatters/money.dart';
import 'package:expenz/models/savings_goal.dart';
import 'package:flutter/material.dart';

class GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final int savedMinor;
  final VoidCallback? onTransfer;
  final bool showTransfer;
  const GoalCard({
    super.key,
    required this.goal,
    required this.savedMinor,
    this.onTransfer,
    this.showTransfer = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (savedMinor / goal.targetMinor).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              color: AppColors.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text(
              '${moneyMinor(savedMinor)} of ${moneyMinor(goal.targetMinor)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showTransfer)
              TextButton.icon(
                onPressed: progress < 1 ? onTransfer : null,
                icon: Icon(
                  progress >= 1
                      ? Icons.check_circle_outline
                      : Icons.savings_outlined,
                ),
                label: Text(progress >= 1 ? 'Goal reached' : 'Add from wallet'),
              ),
          ],
        ),
      ),
    );
  }
}
