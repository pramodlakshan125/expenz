import 'package:expenz/constant/colors.dart';
import 'package:expenz/constant/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCard extends StatefulWidget {
  final double spentAmount;
  final double monthlyBudget;
  final VoidCallback? onArrowTap;

  const BalanceCard({
    super.key,
    required this.spentAmount,
    required this.monthlyBudget,
    this.onArrowTap,
  }) : assert(monthlyBudget > 0);

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isHidden = false;

  String _format(double value) {
    return 'Rs. ${NumberFormat('#,##0').format(value)}';
  }

  Color _progressColor(double progress) {
    const warningStart = 0.7;
    if (progress <= warningStart) {
      return Color.lerp(
            AppColors.safeState,
            AppColors.warningState,
            progress / warningStart,
          ) ??
          AppColors.safeState;
    }

    return Color.lerp(
          AppColors.warningState,
          AppColors.dangerState,
          ((progress - warningStart) / (1 - warningStart)).clamp(0.0, 1.0),
        ) ??
        AppColors.dangerState;
  }

  @override
  Widget build(BuildContext context) {
    final spent = widget.spentAmount.clamp(0.0, double.infinity).toDouble();
    final progress = (spent / widget.monthlyBudget).clamp(0.0, 1.0).toDouble();
    final progressColor = _progressColor(progress);
    final isOverBudget = spent > widget.monthlyBudget;
    final isAtLimit = spent >= widget.monthlyBudget;
    final status = isOverBudget
        ? 'OVER BUDGET'
        : isAtLimit
        ? 'LIMIT REACHED'
        : progress >= 0.7
        ? 'NEAR LIMIT'
        : 'ON TRACK';
    final statusColor = isAtLimit
        ? AppColors.dangerState
        : progress >= 0.7
        ? AppColors.warningState
        : AppColors.safeState;
    final remaining = widget.monthlyBudget - spent;
    final percentUsed = (spent / widget.monthlyBudget * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    AppIcons.wallet,
                    size: 21,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly spending',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your budget progress',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _isHidden ? 'Rs. ••••' : _format(spent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 34,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _isHidden = !_isHidden),
                child: Icon(
                  _isHidden ? Icons.visibility_off_outlined : AppIcons.eye,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
              if (widget.onArrowTap != null) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: widget.onArrowTap,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.north_east_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'of ${_isHidden ? '••••' : _format(widget.monthlyBudget)} budget',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 9,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              semanticsLabel: 'Monthly budget spent',
              semanticsValue: '${(progress * 100).round()}%',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isHidden ? '••••' : '$percentUsed% used',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _isHidden
                    ? '••••'
                    : isOverBudget
                    ? 'Over by ${_format(spent - widget.monthlyBudget)}'
                    : remaining == 0
                    ? 'Budget reached'
                    : '${_format(remaining)} left',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isAtLimit
                      ? AppColors.dangerState
                      : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerState.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.warning,
                    size: 18,
                    color: AppColors.dangerState,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You're over budget. Review your spending plan.",
                      style: TextStyle(
                        color: AppColors.dangerState,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
