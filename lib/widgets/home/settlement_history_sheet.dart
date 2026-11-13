import 'package:expenz/formatters/money.dart';
import 'package:expenz/models/daily_settlement.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SettlementHistorySheet extends StatelessWidget {
  final List<DailySettlement> settlements;
  const SettlementHistorySheet({super.key, required this.settlements});

  @override
  Widget build(BuildContext context) {
    final days = [...settlements]..sort((a, b) => b.date.compareTo(a.date));
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Closed days',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close history',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (days.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No days closed yet.'),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  return ListTile(
                    title: Text(DateFormat('d MMM yyyy').format(day.date)),
                    subtitle: Text(
                      [
                        'Spent ${moneyMinor(day.spentMinor)} of ${moneyMinor(day.adjustedLimitMinor)}',
                        if (day.walletChangeMinor > 0)
                          'Saved ${moneyMinor(day.walletChangeMinor)} to wallet',
                        if (day.walletChangeMinor < 0)
                          'Covered ${moneyMinor(-day.walletChangeMinor)} from wallet',
                        if (day.uncoveredMinor > 0)
                          'Uncovered: ${moneyMinor(day.uncoveredMinor)}',
                        if (day.date.day ==
                                DateTime(
                                  day.date.year,
                                  day.date.month + 1,
                                  0,
                                ).day &&
                            day.carriedAfterMinor > 0)
                          'Month-end outstanding: ${moneyMinor(day.carriedAfterMinor)}. Not carried into next month.',
                      ].join('\n'),
                    ),
                    isThreeLine: false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
