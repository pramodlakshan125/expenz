import 'package:expenz/constant/colors.dart';
import 'package:expenz/formatters/money.dart';
import 'package:expenz/services/daily_budget_calculator.dart';
import 'package:flutter/material.dart';
import 'daily_progress_bar.dart';

class DailyBudgetCard extends StatelessWidget {
  final DailyBudgetResult day;
  final VoidCallback? onEditLimit;

  const DailyBudgetCard({super.key, required this.day, this.onEditLimit});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Daily spending',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Change daily target',
                onPressed: onEditLimit,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DailyProgressBar(
            spentMinor: day.spentMinor,
            limitMinor: day.adjustedLimitMinor,
          ),
          if (day.carriedBeforeMinor > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Your limit is ${moneyMinor(day.adjustedLimitMinor)} today because '
              'of ${moneyMinor(day.carriedBeforeMinor)} overspend earlier.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
