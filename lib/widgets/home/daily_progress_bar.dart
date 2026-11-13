import 'package:expenz/constant/colors.dart';
import 'package:expenz/formatters/money.dart';
import 'package:flutter/material.dart';

class DailyProgressBar extends StatelessWidget {
  final int spentMinor;
  final int limitMinor;

  const DailyProgressBar({
    super.key,
    required this.spentMinor,
    required this.limitMinor,
  }) : assert(spentMinor >= 0 && limitMinor >= 0);

  @override
  Widget build(BuildContext context) {
    final ratio = limitMinor == 0
        ? (spentMinor > 0 ? 1.0 : 0.0)
        : spentMinor / limitMinor;
    final color = ratio >= 1
        ? AppColors.dangerState
        : ratio >= 0.7
        ? AppColors.warningState
        : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${moneyMinor(spentMinor)} of ${moneyMinor(limitMinor)} spent'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 9,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
            semanticsLabel: 'Daily spending target',
            semanticsValue: '${(ratio.clamp(0.0, 1.0) * 100).round()}%',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          spentMinor > limitMinor
              ? 'Over by ${moneyMinor(spentMinor - limitMinor)}'
              : '${moneyMinor(limitMinor - spentMinor)} remaining today',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
