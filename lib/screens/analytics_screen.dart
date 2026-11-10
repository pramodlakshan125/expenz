import 'dart:math' as math;
import 'package:expenz/constant/app_icons.dart';
import 'package:expenz/constant/colors.dart';
import 'package:expenz/data/dummy_transactions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _colors = [
  Color(0xFFCA7029),
  Color(0xFF70794B),
  Color(0xFF3C4C52),
  Color(0xFF5E77AE),
  Color(0xFFDEB61B),
  Color(0xFF8D608C),
];
String _money(num value) => 'Rs. ${NumberFormat('#,##0.##').format(value)}';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _date = DateTime.now();
  String _period = 'Month';
  bool _breakdown = false;
  bool _chart = true;
  String? _category;

  DateTime get _start {
    if (_period == 'Year') return DateTime(_date.year);
    if (_period == 'Month') return DateTime(_date.year, _date.month);
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
    ).subtract(Duration(days: _date.weekday - 1));
  }

  DateTime get _end => switch (_period) {
    'Year' => DateTime(_date.year + 1),
    'Month' => DateTime(_date.year, _date.month + 1),
    _ => _start.add(const Duration(days: 7)),
  };
  String get _label => switch (_period) {
    'Year' => DateFormat('yyyy').format(_date),
    'Month' => DateFormat('MMMM yyyy').format(_date),
    _ =>
      '${DateFormat('d MMM').format(_start)} – ${DateFormat('d MMM yyyy').format(_end.subtract(const Duration(days: 1)))}',
  };
  void _move(int step) => setState(() {
    _date = switch (_period) {
      'Year' => DateTime(_date.year + step, _date.month),
      'Month' => DateTime(_date.year, _date.month + step),
      _ => _date.add(Duration(days: step * 7)),
    };
  });
  void _back() => setState(() {
    if (_category != null) {
      _category = null;
    } else {
      _breakdown = false;
    }
  });

  @override
  Widget build(BuildContext context) {
    final transactions =
        DummyTransactions.list
            .where(
              (t) =>
                  !t.isIncome &&
                  !t.date.isBefore(_start) &&
                  t.date.isBefore(_end),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final totals = <String, double>{};
    for (final t in transactions) {
      totals.update(
        t.category,
        (value) => value + t.amount,
        ifAbsent: () => t.amount,
      );
    }
    final categories = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = transactions.fold<double>(0, (sum, t) => sum + t.amount);
    final selected = transactions
        .where((t) => t.category == _category)
        .toList();
    final categoryTotal = totals[_category] ?? 0;
    return PopScope(
      canPop: !_breakdown && _category == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: ColoredBox(
        color: const Color(0xFFF5F8F7),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              if (_breakdown || _category != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _back,
                    tooltip: 'Back to insights',
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              if (_category != null) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppIcons.categoryColor(_category!),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      AppIcons.category(_category!),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _category!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _money(categoryTotal),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _stat('Transactions', '${selected.length}'),
                    _stat(
                      'Average',
                      _money(
                        selected.isEmpty ? 0 : categoryTotal / selected.length,
                      ),
                    ),
                    _stat(
                      'Biggest',
                      _money(
                        selected.fold<double>(
                          0,
                          (value, t) => math.max(value, t.amount),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _card(
                  Column(
                    children: selected
                        .map(
                          (t) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CategoryIcon(category: t.category),
                            title: Text(t.title),
                            subtitle: Text(
                              DateFormat('d MMM, HH:mm').format(t.date),
                            ),
                            trailing: Text(
                              '-${_money(t.amount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ] else ...[
                Text(
                  _breakdown ? 'Spending by category' : 'Insights',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _breakdown ? _label : 'Where your money went',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 22),
                if (!_breakdown) ...[
                  _segments(
                    ['Week', 'Month', 'Year'],
                    _period,
                    (value) => setState(() => _period = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _move(-1),
                        tooltip: 'Previous period',
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Flexible(
                        child: Text(
                          _label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _move(1),
                        tooltip: 'Next period',
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007F61),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total spent',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _money(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '${transactions.length} expenses · $_label',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else ...[
                  _segments(
                    ['Chart view', 'List view'],
                    _chart ? 'Chart view' : 'List view',
                    (value) => setState(() => _chart = value == 'Chart view'),
                  ),
                  const SizedBox(height: 18),
                ],
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_breakdown)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'By category',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _breakdown = true),
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                      if (categories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Text(
                              'No expenses in this period.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else ...[
                        if (!_breakdown || _chart) ...[
                          Center(
                            child: SizedBox(
                              height: _breakdown ? 240 : 180,
                              width: _breakdown ? 240 : 180,
                              child: CustomPaint(
                                painter: _DonutPainter(
                                  categories.map((e) => e.value).toList(),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _breakdown
                                            ? _money(total)
                                            : '${categories.length}',
                                        style: TextStyle(
                                          fontSize: _breakdown ? 20 : 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _breakdown
                                            ? 'Total spent'
                                            : 'categories',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        for (var i = 0; i < categories.length; i++)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 5,
                              backgroundColor: _colors[i % _colors.length],
                            ),
                            minLeadingWidth: 10,
                            title: Text(
                              categories[i].key,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              '${(categories[i].value / total * 100).round()}% of spending',
                            ),
                            trailing: Text(
                              _money(categories[i].value),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () =>
                                setState(() => _category = categories[i].key),
                          ),
                      ],
                    ],
                  ),
                ),
                if (!_breakdown && categories.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DE),
                      border: Border.all(color: const Color(0xFFE2C559)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          AppIcons.idea,
                          color: Color(0xFF9F7E00),
                          size: 30,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOP INSIGHT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${categories.first.key} is your largest expense category at ${(categories.first.value / total * 100).round()}% of spending.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Based on your current sample transactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
  Widget _card(Widget child) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE5EBE8)),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
  Widget _segments(
    List<String> labels,
    String selected,
    ValueChanged<String> onChanged,
  ) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5EBE8)),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Material(
                color: selected == label ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onChanged(label),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: selected == label
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: selected == label
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  _DonutPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    final stroke = size.shortestSide * 0.16;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start + 0.015,
        math.max(0.0, sweep - 0.03),
        false,
        Paint()
          ..color = _colors[i % _colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
