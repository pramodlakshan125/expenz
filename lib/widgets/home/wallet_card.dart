import 'package:expenz/constant/colors.dart';
import 'package:expenz/formatters/money.dart';
import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  final int walletBalanceMinor;
  final int actualBalanceMinor;
  final VoidCallback? onAdjustBalance;
  final VoidCallback? onAddToWallet;
  final VoidCallback? onTransferToGoal;
  final int availableToSaveMinor;

  const WalletCard({
    super.key,
    required this.walletBalanceMinor,
    required this.actualBalanceMinor,
    this.onAdjustBalance,
    this.onAddToWallet,
    this.onTransferToGoal,
    this.availableToSaveMinor = 0,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.savings_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Savings wallet',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            moneyMinor(walletBalanceMinor),
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved from your daily target. Included in your bank + cash.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onAddToWallet,
                icon: const Icon(Icons.add),
                label: const Text('Add to wallet'),
              ),
              OutlinedButton.icon(
                onPressed: onTransferToGoal,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Transfer to goal'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Available to save: ${moneyMinor(availableToSaveMinor)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Text('Bank + cash balance: ${moneyMinor(actualBalanceMinor)}'),
          TextButton.icon(
            onPressed: onAdjustBalance,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Correct my balance'),
          ),
          if (actualBalanceMinor >= 0 &&
              walletBalanceMinor > actualBalanceMinor)
            const Text(
              'Your wallet target is higher than your recorded funds. '
              'Check your balance before using savings.',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
    ),
  );
}
