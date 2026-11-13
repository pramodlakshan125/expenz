import 'package:expenz/formatters/money.dart';
import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/debt_account.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/services/debt_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DebtDraft {
  final String name;
  final int amountMinor;
  final String accountId;
  final bool movesCash;
  final DateTime date;
  const DebtDraft({
    required this.name,
    required this.amountMinor,
    required this.accountId,
    required this.movesCash,
    required this.date,
  });
}

class DebtsSheet extends StatelessWidget {
  final BudgetController controller;
  final DebtKind kind;
  const DebtsSheet({super.key, required this.controller, required this.kind});

  Future<void> _edit(
    BuildContext context, {
    DebtAccount? debt,
    bool charge = false,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DebtEditor(
        ledger: controller.ledger!,
        kind: kind,
        debt: debt,
        charge: charge,
        onSave: (draft) async {
          final service = DebtService();
          if (debt == null) {
            await service.create(
              name: draft.name,
              kind: kind,
              amountMinor: draft.amountMinor,
              accountId: draft.accountId,
              movesCash: draft.movesCash,
              date: draft.date,
            );
          } else {
            await service.record(
              debt: debt,
              amountMinor: draft.amountMinor,
              accountId: draft.accountId,
              date: draft.date,
              charge: charge,
            );
          }
        },
      ),
    );
  }

  Future<void> _history(
    BuildContext context,
    DebtAccount debt,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final entries =
            controller.ledger!.debtEntries
                .where((entry) => entry.debtId == debt.id)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${debt.name} - History',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                for (final entry in entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(switch (entry.action) {
                      DebtAction.opening => 'Opening balance',
                      DebtAction.repayment =>
                        kind == DebtKind.receivable
                            ? 'Payment received'
                            : 'Payment made',
                      DebtAction.charge => 'Purchase / fee',
                    }),
                    subtitle: Text(
                      '${DateFormat('d MMM yyyy').format(entry.date)}${entry.movesCash ? '' : ' - No cash movement'}',
                    ),
                    trailing: Text(moneyMinor(entry.amountMinor)),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final ledger = controller.ledger!;
      final debts = ledger.debts.where((debt) => debt.kind == kind).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kind.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                moneyMinor(ledger.debtBalanceMinor(kind)),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kind == DebtKind.receivable
                    ? 'Tap a person or company to receive a payment.'
                    : 'Tap a person, company or card to pay.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: controller.canAct ? () => _edit(context) : null,
                icon: const Icon(Icons.add),
                label: Text(
                  kind == DebtKind.creditCard ? 'Add credit card' : 'Add debt',
                ),
              ),
              if (debts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No balances added yet.'),
                ),
              for (final debt in debts)
                Card(
                  margin: const EdgeInsets.only(top: 12),
                  elevation: 0,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          debt.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          debt.remainingMinor == 0
                              ? 'Settled'
                              : moneyMinor(debt.remainingMinor),
                        ),
                        trailing: debt.remainingMinor > 0
                            ? const Icon(Icons.chevron_right)
                            : const Icon(Icons.check_circle_outline),
                        onTap: controller.canAct && debt.remainingMinor > 0
                            ? () => _edit(context, debt: debt)
                            : null,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => _history(context, debt),
                            icon: const Icon(Icons.history, size: 18),
                            label: const Text('History'),
                          ),
                          if (kind == DebtKind.creditCard)
                            TextButton.icon(
                              onPressed: controller.canAct
                                  ? () =>
                                        _edit(context, debt: debt, charge: true)
                                  : null,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add purchase / fee'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class DebtEditor extends StatefulWidget {
  final BudgetLedger ledger;
  final DebtKind kind;
  final DebtAccount? debt;
  final bool charge;
  final Future<void> Function(DebtDraft) onSave;
  const DebtEditor({
    super.key,
    required this.ledger,
    required this.kind,
    this.debt,
    this.charge = false,
    required this.onSave,
  });
  @override
  State<DebtEditor> createState() => _DebtEditorState();
}

class _DebtEditorState extends State<DebtEditor> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  String _accountId = 'cash';
  bool _movesCash = true;
  bool _saving = false;
  String? _error;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool get _opening => widget.debt == null;
  bool get _showAccount =>
      !widget.charge &&
      (widget.debt != null || widget.kind != DebtKind.creditCard && _movesCash);

  @override
  void initState() {
    super.initState();
    if (widget.debt != null && !widget.charge) {
      _amount.text = (widget.debt!.remainingMinor / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        DebtDraft(
          name: _name.text.trim(),
          amountMinor: parseMoneyMinor(_amount.text)!,
          accountId: _accountId,
          movesCash: widget.kind != DebtKind.creditCard && _movesCash,
          date: _date,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is StateError
              ? error.message
              : 'Could not save. Reconnect and try again.';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.debt == null
          ? DateTime(1900)
          : DateUtils.dateOnly(widget.debt!.createdAt),
      lastDate: DateUtils.dateOnly(now),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.charge
        ? 'Add purchase / fee'
        : !_opening
        ? widget.kind == DebtKind.receivable
              ? 'Receive payment'
              : 'Pay'
        : widget.kind == DebtKind.creditCard
        ? 'Add credit card'
        : 'Add debt';
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (_opening) ...[
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    maxLength: 40,
                    decoration: InputDecoration(
                      labelText: widget.kind == DebtKind.creditCard
                          ? 'Card name'
                          : 'Person / company',
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Enter a name.' : null,
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Text(widget.debt!.name),
                  const SizedBox(height: 8),
                  Text('Remaining: ${moneyMinor(widget.debt!.remainingMinor)}'),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _amount,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _opening && widget.kind == DebtKind.creditCard
                        ? 'Amount currently owed'
                        : 'Amount',
                    prefixText: 'Rs. ',
                  ),
                  validator: (value) {
                    final amount = parseMoneyMinor(value ?? '');
                    if (amount == null ||
                        amount == 0 &&
                            !(_opening && widget.kind == DebtKind.creditCard)) {
                      return 'Enter an amount greater than zero.';
                    }
                    if (!_opening &&
                        !widget.charge &&
                        amount > widget.debt!.remainingMinor) {
                      return 'Enter no more than ${moneyMinor(widget.debt!.remainingMinor)}.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (_opening && widget.kind != DebtKind.creditCard)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Move cash / bank money now',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Turn off when recording an existing debt.',
                    ),
                    value: _movesCash,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _movesCash = value),
                  ),
                if (_opening && widget.kind == DebtKind.creditCard)
                  const Text(
                    'An existing card balance does not create income or an expense.',
                  ),
                if (_showAccount) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _accountId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:
                          widget.kind == DebtKind.receivable && !_opening ||
                              widget.kind == DebtKind.payable && _opening
                          ? 'Receive into'
                          : 'Pay from',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'cash',
                        child: Text('Cash in hand'),
                      ),
                      for (final account in widget.ledger.accounts.where(
                        (account) => account.id != 'cash',
                      ))
                        DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _accountId = value!),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(DateFormat('d MMM yyyy').format(_date)),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.charge
                      ? 'Counts as an expense. Cash and bank funds change only when you pay the card.'
                      : 'Principal only. Record loan interest or fees as a separate expense.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            !_opening && !widget.charge
                                ? widget.kind == DebtKind.receivable
                                      ? 'Receive payment'
                                      : 'Pay'
                                : 'Save',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
