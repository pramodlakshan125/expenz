import 'package:expenz/constant/colors.dart';
import 'dart:async';
import 'package:expenz/models/money_account.dart';
import 'package:expenz/services/money_account_service.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AddNewPage extends StatefulWidget {
  final TransactionType initialType;
  final Future<void> Function(TransactionModel)? onSave;
  final List<MoneyAccount> initialAccounts;
  const AddNewPage({
    super.key,
    this.initialType = TransactionType.expense,
    this.onSave,
    this.initialAccounts = const [],
  });

  @override
  State<AddNewPage> createState() => _AddNewPageState();
}

class _AddNewPageState extends State<AddNewPage> {
  static const _green = AppColors.primary;
  static const _expenses = [
    ('Food & Dining', Icons.local_cafe, AppColors.warningState),
    ('Transport', Icons.directions_bus, AppColors.textMuted),
    ('Shopping', Icons.shopping_cart, AppColors.safeState),
    ('Bills & Utilities', Icons.bolt, AppColors.textSecondary),
    ('Entertainment', Icons.movie, AppColors.expense),
    ('Health', Icons.add, AppColors.warningState),
    ('Other', Icons.grid_view_rounded, AppColors.textSecondary),
  ];
  static const _incomes = [
    ('Salary', Icons.payments, _green),
    ('Freelance', Icons.work_outline, AppColors.textMuted),
    ('Gift', Icons.card_giftcard, AppColors.expense),
    ('Other', Icons.grid_view_rounded, AppColors.textSecondary),
  ];
  final Map<TransactionType, List<String>> _categories = {
    TransactionType.expense: _expenses.map((item) => item.$1).toList(),
    TransactionType.income: _incomes.map((item) => item.$1).toList(),
  };
  bool _categoriesReady = false;
  List<MoneyAccount> _accounts = [];
  String _accountId = 'cash';
  bool _accountsReady = false;
  StreamSubscription<List<MoneyAccount>>? _accountsSubscription;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.onSave != null) {
      _accounts = widget.initialAccounts
          .where((account) => account.id != 'cash')
          .toList();
      _accountsReady = true;
    } else {
      _accountsSubscription = MoneyAccountService().watch().listen(
        (accounts) {
          if (!mounted) return;
          setState(() {
            _accounts = accounts
                .where((account) => account.id != 'cash')
                .toList();
            _accountsReady = true;
          });
        },
        onError: (Object error) {
          if (mounted) {
            setState(() {
              _accountsReady = false;
              _error =
                  'Could not load accounts. Reopen this page to try again.';
            });
          }
        },
      );
    }
  }

  Future<void> _loadCategories() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        for (final type in TransactionType.values) {
          _categories[type] =
              preferences.getStringList('categories.${type.name}') ??
              _categories[type]!;
        }
        _categoriesReady = true;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not load categories. Reopen this page to try again.',
        );
      }
    }
  }

  Future<bool> _storeCategories(
    TransactionType type,
    List<String> values,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setStringList('categories.${type.name}', values)) {
        throw StateError('Save failed');
      }
      if (!mounted) return false;
      setState(() => _categories[type] = values);
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save categories. Please try again.');
      }
      return false;
    }
  }

  Future<void> _addCategory() async {
    final type = _type;
    var enteredName = '';
    String? error;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('New category'),
          content: TextField(
            onChanged: (value) => enteredName = value,
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Category name',
              hintText: 'e.g. Daily coffee',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = enteredName.trim();
                if (value.isEmpty) {
                  update(() => error = 'Enter a category name.');
                  return;
                }
                if (_categories[type]!.any(
                  (name) => name.toLowerCase() == value.toLowerCase(),
                )) {
                  update(() => error = 'This category already exists.');
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    // The dialog route can still be animating out with its text field attached.
    if (name == null || !mounted) return;
    if (await _storeCategories(type, [..._categories[type]!, name]) &&
        mounted) {
      setState(() {
        _category = name;
        _error = null;
      });
    }
  }

  Future<void> _deleteCategory(String name) async {
    if (_saving || !_categoriesReady) return;
    final type = _type;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text(
          'This removes the category from your choices. Existing transactions stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (await _storeCategories(
          type,
          _categories[type]!.where((value) => value != name).toList(),
        ) &&
        mounted) {
      setState(() {
        if (_category == name) _category = null;
      });
    }
  }

  Widget _categoryChip(String name) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Delete category'): () =>
            _deleteCategory(name),
      },
      child: RawGestureDetector(
        gestures: {
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                  duration: const Duration(seconds: 2),
                ),
                (recognizer) =>
                    recognizer.onLongPress = _saving || !_categoriesReady
                    ? null
                    : () => _deleteCategory(name),
              ),
        },
        child: ChoiceChip(
          label: Text(name),
          selected: _category == name,
          selectedColor: _green,
          backgroundColor: colors.surface,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: _category == name ? Colors.white : colors.onSurface,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: _saving || !_categoriesReady
              ? null
              : (_) => setState(() {
                  _category = name;
                  _error = null;
                }),
        ),
      ),
    );
  }

  final _amount = TextEditingController();
  final _note = TextEditingController();
  late TransactionType _type = widget.initialType;
  int _step = 0;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String? _category;
  String? _error;
  bool _saving = false;
  TransactionModel? _saved;
  double get _value => double.tryParse(_amount.text) ?? 0;
  String _money(double amount) =>
      'Rs. ${NumberFormat('#,##0.##').format(amount)}';

  @override
  void dispose() {
    unawaited(_accountsSubscription?.cancel());
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_accountsReady) return;
    if (!_value.isFinite || _value <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    if (_category == null) {
      setState(() => _error = 'Choose a category.');
      return;
    }
    if (_date.isAfter(DateUtils.dateOnly(DateTime.now()))) {
      setState(() => _error = 'Choose today or an earlier date.');
      return;
    }
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
      date: DateTime(
        _date.year,
        _date.month,
        _date.day,
        now.hour,
        now.minute,
        now.second,
      ),
      type: _type,
      accountId: _accountId,
    );
    try {
      if (widget.onSave != null) {
        await widget.onSave!(transaction);
      } else {
        TransactionService().queue(transaction);
      }
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
    final colors = Theme.of(context).colorScheme;
    final income = _type == TransactionType.income;
    final categories = _categories[_type]!;
    final saved = _step == 2;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            saved
                ? 'Transaction saved'
                : income
                ? 'Add income'
                : 'Add expense',
          ),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: !_saving,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: saved
                          ? Column(
                              children: [
                                const SizedBox(height: 32),
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: _green,
                                  size: 64,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _money(_saved!.amount),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                _detail('Title', _saved!.title),
                                _detail('Category', _saved!.category),
                                _detail(
                                  'Date',
                                  DateFormat('d MMM yyyy').format(_saved!.date),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: SegmentedButton<TransactionType>(
                                    segments: const [
                                      ButtonSegment(
                                        value: TransactionType.expense,
                                        label: Text('Expense'),
                                      ),
                                      ButtonSegment(
                                        value: TransactionType.income,
                                        label: Text('Income'),
                                      ),
                                    ],
                                    selected: {_type},
                                    showSelectedIcon: false,
                                    style: SegmentedButton.styleFrom(
                                      selectedBackgroundColor: _green,
                                      selectedForegroundColor: Colors.white,
                                      minimumSize: const Size(48, 48),
                                    ),
                                    onSelectionChanged: _saving
                                        ? null
                                        : (selection) => setState(() {
                                            _type = selection.first;
                                            _category = null;
                                            _error = null;
                                          }),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _calendar(),
                                const SizedBox(height: 24),
                                _label(
                                  income ? 'Income title' : 'Expense title',
                                ),
                                TextField(
                                  controller: _note,
                                  enabled: !_saving,
                                  maxLength: 120,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: _input(
                                    income
                                        ? 'e.g. Side business'
                                        : 'e.g. Groceries',
                                  ).copyWith(counterText: ''),
                                ),
                                const SizedBox(height: 20),
                                _label('Amount'),
                                TextField(
                                  controller: _amount,
                                  enabled: !_saving,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    TextInputFormatter.withFunction(
                                      (oldValue, newValue) =>
                                          RegExp(
                                            r'^\d{0,10}(\.\d{0,2})?$',
                                          ).hasMatch(newValue.text)
                                          ? newValue
                                          : oldValue,
                                    ),
                                  ],
                                  decoration: _input(
                                    '0.00',
                                  ).copyWith(suffixText: 'LKR'),
                                  onChanged: (_) =>
                                      setState(() => _error = null),
                                ),
                                const SizedBox(height: 20),
                                _label(income ? 'Receive into' : 'Pay from'),
                                DropdownButtonFormField<String>(
                                  initialValue: _accountId,
                                  isExpanded: true,
                                  decoration: _input('Choose account'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: 'cash',
                                      child: Text('Cash in hand'),
                                    ),
                                    for (final account in _accounts)
                                      DropdownMenuItem(
                                        value: account.id,
                                        child: Text(account.name),
                                      ),
                                  ],
                                  onChanged: _saving || !_accountsReady
                                      ? null
                                      : (value) =>
                                            setState(() => _accountId = value!),
                                ),
                                if (!_accountsReady)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text('Loading accounts…'),
                                  ),
                                const SizedBox(height: 24),
                                _label(
                                  income
                                      ? 'Income category'
                                      : 'Expense category',
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: OutlinedButton(
                                        onPressed: _saving || !_categoriesReady
                                            ? null
                                            : _addCategory,
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Semantics(
                                          label: 'Add category',
                                          child: Icon(Icons.add),
                                        ),
                                      ),
                                    ),
                                    for (final category in categories)
                                      _categoryChip(category),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hold a category for 2 seconds to delete it.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _error!,
                                        style: TextStyle(color: colors.error),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saving || !_accountsReady
                            ? null
                            : saved
                            ? () => Navigator.pop(context)
                            : _save,
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
                                saved
                                    ? 'Done'
                                    : income
                                    ? 'Add income'
                                    : 'Add expense',
                              ),
                      ),
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

  InputDecoration _input(String hint) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green, width: 2),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _calendar() {
    final colors = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final currentMonth = DateTime(today.year, today.month);
    final offset = _month.weekday - 1;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: _saving || _month.year <= 1900 && _month.month == 1
                    ? null
                    : () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: _saving || !_month.isBefore(currentMonth)
                    ? null
                    : () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final day in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Each date retains a 48dp touch target, including on narrow screens.
          for (var row = 0; row < ((offset + days) / 7).ceil(); row++)
            Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: _dayCell(row * 7 + column - offset + 1, days, today),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEE, d MMM yyyy').format(_date),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(int day, int days, DateTime today) {
    if (day < 1 || day > days) return const SizedBox(height: 48);
    final date = DateTime(_month.year, _month.month, day);
    final selected = DateUtils.isSameDay(_date, date);
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: _saving || date.isAfter(today)
            ? null
            : () => setState(() => _date = date),
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          backgroundColor: selected ? _green : null,
          foregroundColor: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Semantics(
          label: DateFormat('EEEE, d MMMM yyyy').format(date),
          selected: selected,
          child: ExcludeSemantics(child: Text('$day')),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        Text(label),
        const SizedBox(width: 16),
        Expanded(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );
}
