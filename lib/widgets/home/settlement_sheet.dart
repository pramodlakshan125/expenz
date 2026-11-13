import 'package:expenz/formatters/money.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/services/daily_budget_planner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SettlementSheet extends StatelessWidget {
  final BudgetController controller;
  const SettlementSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final day = controller.plan?.nextUnsettledDay;
      final wallet = controller.ledger?.walletBalanceMinor ?? 0;
      final overspent = day?.overspentMinor ?? 0;
      final covered = overspent < wallet ? overspent : wallet;
      void answer(bool yes) {
        try {
          controller.settleNext(
            expectedDayKey: DailyBudgetPlanner.dateKey(day!.date),
            useWallet: yes,
          );
        } catch (error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$error')));
        }
      }

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Close your day',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Review later',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (controller.error != null) ...[
                const Text(
                  'This save could not sync. Reconnect and retry before closing more days.',
                ),
                TextButton(
                  onPressed: controller.retry,
                  child: const Text('Retry'),
                ),
              ] else if (day == null) ...[
                const Text(
                  'All previous days are closed. Today stays open for new expenses.',
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ] else ...[
                Text(DateFormat('EEEE, d MMM yyyy').format(day.date)),
                const SizedBox(height: 12),
                Text('Target: ${moneyMinor(day.adjustedLimitMinor)}'),
                Text('Spent: ${moneyMinor(day.spentMinor)}'),
                Text('Wallet: ${moneyMinor(wallet)}'),
                const SizedBox(height: 20),
                Text(
                  day.leftoverMinor > 0
                      ? 'Save ${moneyMinor(day.leftoverMinor)} to your wallet?'
                      : overspent > 0 && covered > 0
                      ? 'Cover ${moneyMinor(covered)} from your wallet?'
                      : overspent > 0
                      ? 'Your wallet is empty. Carry ${moneyMinor(overspent)} forward?'
                      : 'You spent exactly your target. Close this day?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (overspent > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    day.remainingDaysIncludingToday == 1
                        ? 'Any uncovered amount stays in this month’s history. Next month starts fresh.'
                        : 'Uncovered overspend is shared across the ${day.remainingDaysIncludingToday - 1} remaining days of this month.',
                  ),
                  if (covered > 0 && covered < overspent)
                    Text(
                      '${moneyMinor(overspent - covered)} will still be uncovered.',
                    ),
                ],
                const SizedBox(height: 20),
                if (controller.saving) const LinearProgressIndicator(),
                Row(
                  children: [
                    if (day.leftoverMinor > 0 || covered > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.canAct
                              ? () => answer(false)
                              : null,
                          child: const Text('No'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: controller.canAct
                            ? () => answer(true)
                            : null,
                        child: Text(
                          day.leftoverMinor > 0 || covered > 0
                              ? 'Yes'
                              : 'Close day',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${controller.plan!.unsettledCount} day(s) left to review',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
