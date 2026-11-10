import 'package:expenz/constant/colors.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddNewPage extends StatefulWidget {
  final TransactionType initialType;
  final Future<void> Function(TransactionModel)? onSave;
  const AddNewPage({
    super.key,
    this.initialType = TransactionType.expense,
    this.onSave,
  });

  @override
  State<AddNewPage> createState() => _AddNewPageState();
}

class _AddNewPageState extends State<AddNewPage> {
  static const _green = Color(0xFF007D60);
  static const _expenses = [
    ('Food & Dining', Icons.local_cafe, Color(0xFFC7712A)),
    ('Transport', Icons.directions_bus, Color(0xFF5C75AB)),
    ('Shopping', Icons.shopping_cart, Color(0xFF747B43)),
    ('Bills & Utilities', Icons.bolt, Color(0xFF3C4C53)),
    ('Entertainment', Icons.movie, Color(0xFF8C5D88)),
    ('Health', Icons.add, Color(0xFFDDB518)),
    ('Other', Icons.grid_view_rounded, Color(0xFF71817A)),
  ];
  static const _incomes = [
    ('Salary', Icons.payments, _green),
    ('Freelance', Icons.work_outline, Color(0xFF5C75AB)),
    ('Gift', Icons.card_giftcard, Color(0xFF8C5D88)),
    ('Other', Icons.grid_view_rounded, Color(0xFF71817A)),
  ];
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late TransactionType _type = widget.initialType;
  int _step = 0;
  String? _category;
  String? _error;
  bool _saving = false;
  TransactionModel? _saved;
  double get _value => double.tryParse(_amount.text) ?? 0;
  String _money(double amount) =>
      'Rs. ${NumberFormat('#,##0.##').format(amount)}';

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_value.isFinite || _value <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _step = 1;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving || _category == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final now = DateTime.now();
    final transaction = TransactionModel(
      id: now.microsecondsSinceEpoch.toString(),
      title: _note.text.trim().isEmpty ? _category! : _note.text.trim(),
      category: _category!,
      amount: _value,
      date: now,
      type: _type,
    );
    try {
      await (widget.onSave ?? TransactionService().add)(transaction);
      if (!mounted) return;
      setState(() {
        _saved = transaction;
        _step = 2;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == TransactionType.expense ? _expenses : _incomes;
    return PopScope(
      canPop: !_saving && _step != 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving) setState(() => _step = 0);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: _step == 2
              ? null
              : IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _saving
                      ? null
                      : () {
                          if (_step == 1) {
                            setState(() => _step = 0);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _step == 0
                                ? 'Enter amount'
                                : _step == 1
                                ? 'Choose category'
                                : 'Transaction saved',
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _step == 0
                                ? 'How much did you spend or receive?'
                                : _step == 1
                                ? 'What was this transaction for?'
                                : '${_money(_saved!.amount)} was added to ${_saved!.category}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF48544F),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_step == 0) ...[
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<TransactionType>(
                                segments: const [
                                  ButtonSegment(
                                    value: TransactionType.expense,
                                    icon: Icon(Icons.arrow_upward, size: 17),
                                    label: Text('Expense'),
                                  ),
                                  ButtonSegment(
                                    value: TransactionType.income,
                                    icon: Icon(Icons.arrow_downward, size: 17),
                                    label: Text('Income'),
                                  ),
                                ],
                                selected: {_type},
                                showSelectedIcon: false,
                                style: SegmentedButton.styleFrom(
                                  selectedBackgroundColor: const Color(
                                    0xFFE6F4EE,
                                  ),
                                  selectedForegroundColor: _green,
                                ),
                                onSelectionChanged: (selection) => setState(() {
                                  _type = selection.first;
                                  _category = null;
                                }),
                              ),
                            ),
                            const SizedBox(height: 36),
                            TextField(
                              controller: _amount,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                TextInputFormatter.withFunction(
                                  (oldValue, newValue) =>
                                      RegExp(r'^\d{0,10}(\.\d{0,2})?$')
                                          .hasMatch(newValue.text)
                                      ? newValue
                                      : oldValue,
                                ),
                              ],
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                suffixText: 'LKR',
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: _green,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() => _error = null),
                              onSubmitted: (_) => _continue(),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final value in [1000, 5000, 10000])
                                  ActionChip(
                                    label: Text(
                                      '+${NumberFormat('#,##0').format(value)}',
                                    ),
                                    onPressed: () => setState(() {
                                      _amount.text = (_value + value)
                                          .toStringAsFixed(2);
                                      _error = null;
                                    }),
                                  ),
                              ],
                            ),
                          ],
                          if (_step == 1) ...[
                            for (final category in categories)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: _category == category.$1
                                          ? _green
                                          : AppColors.divider,
                                      width: _category == category.$1 ? 2 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: category.$3,
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Icon(
                                        category.$2,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    title: Text(
                                      category.$1,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: Icon(
                                      _category == category.$1
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: _category == category.$1
                                          ? _green
                                          : const Color(0xFF8A9690),
                                    ),
                                    onTap: _saving
                                        ? null
                                        : () => setState(
                                            () => _category = category.$1,
                                          ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _note,
                              enabled: !_saving,
                              maxLength: 120,
                              decoration: const InputDecoration(
                                labelText: 'Note (optional)',
                                hintText: 'e.g. Lunch with team',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_step == 2) ...[
                            const SizedBox(height: 20),
                            const CircleAvatar(
                              radius: 44,
                              backgroundColor: Color(0xFFE7F5EF),
                              child: Icon(Icons.check, size: 46, color: _green),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.divider),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  _detail(
                                    'Amount',
                                    '${_saved!.isIncome ? '+' : '−'}${_money(_saved!.amount)}',
                                  ),
                                  const Divider(height: 1),
                                  _detail('Category', _saved!.category),
                                  if (_note.text.trim().isNotEmpty) ...[
                                    const Divider(height: 1),
                                    _detail('Note', _note.text.trim()),
                                  ],
                                  const Divider(height: 1),
                                  _detail(
                                    'Date',
                                    'Today, ${DateFormat('d MMM yyyy').format(_saved!.date)}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.expense,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _green,
                            ),
                            onPressed:
                                _saving || _step == 1 && _category == null
                                ? null
                                : _step == 0
                                ? _continue
                                : _step == 1
                                ? _save
                                : () => Navigator.pop(context),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _step == 2 ? 'Done' : 'Continue',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        if (_step == 2)
                          TextButton(
                            onPressed: () => setState(() {
                              _step = 0;
                              _amount.clear();
                              _note.clear();
                              _category = null;
                              _saved = null;
                              _error = null;
                            }),
                            child: const Text(
                              'Add another transaction',
                              style: TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF65716C))),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
