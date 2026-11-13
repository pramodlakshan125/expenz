import 'package:expenz/constant/colors.dart';
import 'package:expenz/formatters/money.dart';
import 'package:expenz/models/money_account.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/services/money_account_service.dart';
import 'package:flutter/material.dart';

class AccountsSheet extends StatelessWidget {
  final BudgetController controller;
  const AccountsSheet({super.key, required this.controller});

  Future<void> _edit(BuildContext context, MoneyAccount? account) async {
    final form = GlobalKey<FormState>();
    final ledger = controller.ledger!;
    final name = TextEditingController(text: account?.name ?? '');
    final amount = TextEditingController(
      text: account == null
          ? ''
          : (account.balanceMinor(
                      ledger.transactions,
                      debtEntries: ledger.debtEntries,
                    ) /
                    100)
                .toStringAsFixed(2),
    );
    final result = await showDialog<({String name, int amount})>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          account == null ? 'Add bank account' : 'Update bank account',
        ),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  hintText: 'e.g. Commercial Bank',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter an account name.'
                    : null,
              ),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current balance',
                  prefixText: 'Rs. ',
                ),
                validator: (value) => parseMoneyMinor(value ?? '') == null
                    ? 'Enter zero or a positive amount.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, (
                  name: name.text.trim(),
                  amount: parseMoneyMinor(amount.text)!,
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Wait for the dialog's exit animation before releasing its controllers.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
    amount.dispose();
    if (result == null || !context.mounted) return;
    if (!controller.canAct) return;
    // Use the latest transactions if another write arrived while editing.
    MoneyAccountService().save(
      account: account,
      name: result.name,
      balanceMinor: result.amount,
      transactions: controller.ledger!.transactions,
      debtEntries: controller.ledger!.debtEntries,
      onError: (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not sync account balance. Please retry.'),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final ledger = controller.ledger!;
      final banks = ledger.accounts
          .where((account) => account.id != 'cash')
          .toList();
      final bankTotal = banks.fold<int>(
        0,
        (sum, account) =>
            sum +
            account.balanceMinor(
              ledger.transactions,
              debtEntries: ledger.debtEntries,
            ),
      );
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank accounts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Bank accounts total: ${moneyMinor(bankTotal)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Manage your bank accounts and current balances.'),
              const SizedBox(height: 16),
              for (final account in banks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.account_balance_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(account.name),
                  subtitle: Text(
                    moneyMinor(
                      account.balanceMinor(
                        ledger.transactions,
                        debtEntries: ledger.debtEntries,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: controller.canAct
                      ? () => _edit(context, account)
                      : null,
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.canAct
                    ? () => _edit(context, null)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text('Add bank account'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
