import 'package:expenz/formatters/money.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:flutter/material.dart';

class SavingsTransferSheet extends StatefulWidget {
  final BudgetController controller;
  final bool toGoal;
  final String? initialGoalId;
  const SavingsTransferSheet({
    super.key,
    required this.controller,
    this.toGoal = false,
    this.initialGoalId,
  });

  @override
  State<SavingsTransferSheet> createState() => _SavingsTransferSheetState();
}

class _SavingsTransferSheetState extends State<SavingsTransferSheet> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late String? _goalId = widget.initialGoalId;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted || !_form.currentState!.validate()) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    try {
      final amount = parseMoneyMinor(_amount.text)!;
      if (widget.toGoal) {
        widget.controller.transferToGoal(goalId: _goalId!, amountMinor: amount);
      } else {
        widget.controller.addToWallet(amount);
      }
      if (widget.controller.error != null) {
        throw StateError('Could not queue your savings change. Please retry.');
      }
      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _submitted = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final ledger = widget.controller.ledger;
      final goals =
          ledger?.goals
              .where((goal) => ledger.goalRemainingMinor(goal) > 0)
              .toList() ??
          [];
      final selected = goals.where((goal) => goal.id == _goalId).firstOrNull;
      final wallet = ledger?.walletBalanceMinor ?? 0;
      final remaining = selected == null
          ? wallet
          : ledger!.goalRemainingMinor(selected);
      final maximum = widget.toGoal
          ? (wallet < remaining ? wallet : remaining)
          : ledger?.availableToSaveMinor ?? 0;
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.toGoal ? 'Transfer wallet to goal' : 'Add to wallet',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.toGoal
                      ? 'Move existing savings into your goal. This reduces your wallet by the same amount.'
                      : 'Set aside money from your recorded bank + cash. This does not add new income.',
                ),
                const SizedBox(height: 16),
                if (widget.toGoal) ...[
                  Text('Wallet balance: ${moneyMinor(wallet)}'),
                  const SizedBox(height: 12),
                  if (goals.isEmpty)
                    const Text(
                      'Create a goal first, or choose a goal that has not reached its target.',
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selected?.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Savings goal',
                      ),
                      items: goals
                          .map(
                            (goal) => DropdownMenuItem(
                              value: goal.id,
                              child: Text(
                                goal.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _submitted
                          ? null
                          : (value) => setState(() {
                              _goalId = value;
                              _error = null;
                            }),
                      validator: (_) =>
                          selected == null ? 'Choose a savings goal.' : null,
                    ),
                  if (selected != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${moneyMinor(remaining)} left to reach this goal.',
                      ),
                    ),
                ] else ...[
                  Text('Available to set aside: ${moneyMinor(maximum)}'),
                  const SizedBox(height: 6),
                  const Text(
                    'Amounts already in your wallet and goals are excluded.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                if (maximum == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      widget.toGoal
                          ? 'Add money to your wallet first.'
                          : 'Add income or correct your bank + cash balance before adding savings.',
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amount,
                  enabled: !_submitted,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'Rs. ',
                  ),
                  validator: (text) {
                    final amount = parseMoneyMinor(text ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter a positive amount with up to 2 decimals.';
                    }
                    if (amount > maximum) {
                      return 'Enter no more than ${moneyMinor(maximum)}.';
                    }
                    return null;
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        !_submitted &&
                            widget.controller.canAct &&
                            maximum > 0 &&
                            (!widget.toGoal || goals.isNotEmpty)
                        ? _submit
                        : null,
                    child: Text(
                      widget.toGoal ? 'Transfer to goal' : 'Add to wallet',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
