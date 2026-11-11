import 'package:expenz/constant/colors.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/constant/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  final List<TransactionModel> transactions;
  final bool loading;
  final bool hasError;
  const TransactionPage({
    super.key,
    this.transactions = const [],
    this.loading = false,
    this.hasError = false,
  });

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  static const _green = AppColors.primary;
  final _search = TextEditingController();
  String _type = 'All';
  DateTimeRange? _range;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _money(num value) => 'Rs. ${NumberFormat('#,##0.##').format(value)}';
  double _net(List<TransactionModel> list) => list.fold<double>(
    0,
    (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
  );
  String _signed(double value) =>
      '${value < 0 ? '−' : '+'}${_money(value.abs())}';

  Future<void> _filterDates() async {
    final now = DateTime.now();
    final earliest = widget.transactions.fold<DateTime>(
      DateTime(now.year - 10),
      (date, t) => t.date.isBefore(date) ? t.date : date,
    );
    final latest = widget.transactions.fold<DateTime>(
      DateTime(now.year + 1, 12, 31),
      (date, t) => t.date.isAfter(date) ? t.date : date,
    );
    final result = await showDateRangePicker(
      context: context,
      firstDate: earliest,
      lastDate: latest,
      initialDateRange: _range,
      helpText: 'Filter transaction dates',
    );
    if (result != null && mounted) setState(() => _range = result);
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return DateFormat('d MMMM yyyy').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final dated = widget.transactions
        .where(
          (t) =>
              _range == null ||
              (!t.date.isBefore(_range!.start) &&
                  t.date.isBefore(
                    DateTime(
                      _range!.end.year,
                      _range!.end.month,
                      _range!.end.day + 1,
                    ),
                  )),
        )
        .toList();
    final visible =
        dated
            .where(
              (t) =>
                  (_type == 'All' ||
                      (_type == 'Income' ? t.isIncome : !t.isIncome)) &&
                  (query.isEmpty ||
                      '${t.title} ${t.category}'.toLowerCase().contains(query)),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final groups = <DateTime, List<TransactionModel>>{};
    for (final t in visible) {
      final day = query.isEmpty
          ? DateTime(t.date.year, t.date.month, t.date.day)
          : DateTime(t.date.year, t.date.month);
      groups.putIfAbsent(day, () => []).add(t);
    }
    final now = DateTime.now();
    final summary = _range == null
        ? dated
              .where(
                (t) => t.date.year == now.year && t.date.month == now.month,
              )
              .toList()
        : dated;
    final income = summary
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = summary
        .where((t) => !t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'All your transactions',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _filterDates,
                          tooltip: 'Filter dates',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            foregroundColor: _green,
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          icon: Icon(AppIcons.filter),
                        ),
                      ],
                    ),
                    SizedBox(height: 22),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search transactions',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        prefixIcon: Icon(
                          AppIcons.search,
                          size: 21,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: Icon(AppIcons.close, size: 18),
                                onPressed: () => setState(_search.clear),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: _green, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Expenses', 'Income']
                          .map(
                            (type) => ChoiceChip(
                              label: Text(type),
                              selected: _type == type,
                              showCheckmark: false,
                              selectedColor: _green,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              labelStyle: TextStyle(
                                color: _type == type
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              shape: StadiumBorder(),
                              side: BorderSide(
                                color: _type == type
                                    ? _green
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                              ),
                              onSelected: (_) => setState(() => _type = type),
                            ),
                          )
                          .toList(),
                    ),
                    if (_range != null)
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: InputChip(
                          label: Text(
                            '${DateFormat('d MMM yy').format(_range!.start)} – ${DateFormat('d MMM yy').format(_range!.end)}',
                          ),
                          onDeleted: () => setState(() => _range = null),
                          deleteButtonTooltipMessage: 'Clear date filter',
                        ),
                      ),
                    SizedBox(height: 16),
                    if (!widget.loading && !widget.hasError)
                      if (query.isEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: _summary(
                                'Money in · ${_range == null ? DateFormat('MMM').format(now) : 'Selected dates'}',
                                '+${_money(income)}',
                                _green,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _summary(
                                'Money out · ${_range == null ? DateFormat('MMM').format(now) : 'Selected dates'}',
                                '−${_money(expense)}',
                                Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${visible.length} results',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              'Total ${_signed(_net(visible))}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
            ),
            if (widget.loading || widget.hasError || visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: widget.loading
                        ? CircularProgressIndicator(color: _green)
                        : Text(
                            widget.hasError
                                ? 'Could not load transactions. Check your connection.'
                                : widget.transactions.isEmpty
                                ? 'No transactions yet. Tap + to add one.'
                                : 'No matching transactions. Try another search or filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
                sliver: SliverList.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final entry = groups.entries.elementAt(index);
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  query.isEmpty
                                      ? _dayLabel(entry.key)
                                      : DateFormat(
                                          'MMMM yyyy',
                                        ).format(entry.key),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (query.isEmpty)
                                Text(
                                  _signed(_net(entry.value)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _card(
                          Column(
                            children: [
                              for (var i = 0; i < entry.value.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                _transaction(entry.value[i], query.isNotEmpty),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: child),
  );
  Widget _summary(String label, String amount, Color color) => _card(
    Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 5),
          Text(
            amount,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    ),
  );
  Widget _transaction(TransactionModel t, bool searching) => Padding(
    padding: EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppIcons.categoryColor(t.category),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            AppIcons.category(t.category),
            color: Colors.white,
            size: 23,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 5),
              Text(
                '${t.category} · ${DateFormat(searching ? 'd MMM, HH:mm' : 'HH:mm').format(t.date)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            '${t.isIncome ? '+' : '−'}${_money(t.amount)}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: t.isIncome
                  ? _green
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}
