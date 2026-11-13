import 'package:expenz/constant/colors.dart';
import 'package:expenz/formatters/money.dart';
import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/debt_account.dart';
import 'package:flutter/material.dart';

class FundsSummary extends StatelessWidget {
  final BudgetLedger ledger;
  final DateTime today;
  final VoidCallback? onAccounts;
  final ValueChanged<DebtKind>? onDebts;
  const FundsSummary({
    super.key,
    required this.ledger,
    required this.today,
    this.onAccounts,
    this.onDebts,
  });

  @override
  Widget build(BuildContext context) {
    final spent = ledger.transactions
        .where(
          (entry) =>
              !entry.isIncome &&
              DateUtils.isSameDay(entry.date.toLocal(), today.toLocal()),
        )
        .fold<int>(0, (sum, entry) => sum + (entry.amount * 100).round());
    final banks = ledger.accounts.where((account) => account.id != 'cash');
    final bankTotal = banks.fold<int>(
      0,
      (sum, account) =>
          sum +
          account.balanceMinor(
            ledger.transactions,
            debtEntries: ledger.debtEntries,
          ),
    );
    final cash = ledger.actualBalanceMinor - bankTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your balances',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              'Swipe to view',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          key: const ValueKey('funds-carousel'),
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _card(
                  context,
                  icon: Icons.receipt_long_outlined,
                  title: "Today's expenses",
                  amount: moneyMinor(spent),
                ),
                _card(
                  context,
                  icon: Icons.payments_outlined,
                  title: 'Cash balance',
                  amount: moneyMinor(cash),
                ),
                _card(
                  context,
                  icon: Icons.account_balance_outlined,
                  title: 'Bank balance',
                  amount: moneyMinor(bankTotal),
                  onTap: onAccounts,
                ),
                for (final kind in DebtKind.values)
                  _card(
                    context,
                    icon: switch (kind) {
                      DebtKind.receivable => Icons.call_received_rounded,
                      DebtKind.payable => Icons.call_made_rounded,
                      DebtKind.creditCard => Icons.credit_card_outlined,
                    },
                    title: kind.label,
                    amount: moneyMinor(ledger.debtBalanceMinor(kind)),
                    onTap: onDebts == null ? null : () => onDebts!(kind),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String amount,
    VoidCallback? onTap,
  }) => Container(
    width: 188,
    margin: const EdgeInsets.only(right: 12),
    child: Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
