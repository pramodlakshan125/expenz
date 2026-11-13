import 'package:expenz/formatters/money.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/services/balance_reconciliation.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/services/transaction_service.dart';
import 'package:flutter/material.dart';

class BalanceCorrectionSheet extends StatefulWidget {
  final BudgetController controller;
  const BalanceCorrectionSheet({super.key, required this.controller});

  @override
  State<BalanceCorrectionSheet> createState() => _BalanceCorrectionSheetState();
}

class _BalanceCorrectionSheetState extends State<BalanceCorrectionSheet> {
  final _form = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _cash = TextEditingController();
  TransactionModel? _adjustment;
  int? _previewBalance;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _bank.dispose();
    _cash.dispose();
    super.dispose();
  }

  void _preview() {
    if (!_form.currentState!.validate()) return;
    final balance = widget.controller.ledger!.actualBalanceMinor;
    final now = widget.controller.clock();
    setState(() {
      _previewBalance = balance;
      _error = null;
      _adjustment = const BalanceReconciliation().adjustment(
        recordedBalanceMinor: balance,
        bankMinor: parseMoneyMinor(_bank.text)!,
        cashMinor: parseMoneyMinor(_cash.text)!,
        now: now,
        id: 'balance-adjustment-${now.microsecondsSinceEpoch}',
      );
    });
  }

  void _save() {
    if (_saving || _adjustment == null) return;
    if (!widget.controller.canAct ||
        widget.controller.ledger!.actualBalanceMinor != _previewBalance) {
      setState(() {
        _previewBalance = null;
        _error = 'Your balance changed. Review the adjustment again.';
      });
      return;
    }
    setState(() => _saving = true);
    try {
      TransactionService().queue(_adjustment!);
      Navigator.pop(context, true);
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Could not save the adjustment. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
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
            const Text(
              'Correct my balance',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter all your bank funds and cash, including money you set aside as savings. Do not add the savings wallet again.',
            ),
            const SizedBox(height: 16),
            for (final input in [
              (label: 'Bank balance', controller: _bank),
              (label: 'Cash in hand', controller: _cash),
            ]) ...[
              TextFormField(
                controller: input.controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: input.label,
                  prefixText: 'Rs. ',
                ),
                validator: (text) => parseMoneyMinor(text ?? '') == null
                    ? 'Enter zero or a positive amount with up to 2 decimals.'
                    : null,
                onChanged: (_) => setState(() {
                  _previewBalance = null;
                  _error = null;
                }),
              ),
              const SizedBox(height: 12),
            ],
            if (_error != null) Text(_error!),
            if (_previewBalance != null) ...[
              const Divider(),
              Text('Recorded balance: ${moneyMinor(_previewBalance!)}'),
              Text(
                'Actual balance: ${moneyMinor(parseMoneyMinor(_bank.text)! + parseMoneyMinor(_cash.text)!)}',
              ),
              const SizedBox(height: 8),
              Text(
                _adjustment == null
                    ? 'Your balance already matches.'
                    : '${_adjustment!.title}: ${moneyMinor((_adjustment!.amount * 100).round())}',
              ),
              if (_adjustment != null && !_adjustment!.isIncome)
                const Text(
                  'This expense counts toward today’s spending. Closed days stay unchanged.',
                ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : _previewBalance == null
                    ? _preview
                    : _adjustment == null
                    ? () => Navigator.pop(context)
                    : _save,
                child: Text(
                  _previewBalance == null
                      ? 'Review adjustment'
                      : _adjustment == null
                      ? 'Done'
                      : 'Confirm adjustment',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
