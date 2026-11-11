import 'dart:math' as math;
import 'package:expenz/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingTrends extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool isSample;
  const SpendingTrends({
    super.key,
    required this.transactions,
    this.isSample = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - 11 + i),
    );
    final values = months
        .map(
          (month) => transactions
              .where(
                (t) =>
                    !t.isIncome &&
                    t.date.year == month.year &&
                    t.date.month == month.month,
              )
              .fold<double>(0, (sum, t) => sum + t.amount),
        )
        .toList();
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final average = total / 12;
    final highest = values.indexOf(values.reduce(math.max));
    final lowest = values.indexOf(values.reduce(math.min));
    final change = average == 0 ? 0.0 : (values.last / average - 1) * 100;
    final scheme = Theme.of(context).colorScheme;
    String money(double value) => 'Rs. ${NumberFormat('#,##0').format(value)}';
    Widget card(Widget child) => Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Spending trends')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last 12 months · includes the current month',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          if (isSample) ...[
            const Text('Based on sample transactions'),
            const SizedBox(height: 12),
          ],
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly average',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  money(average),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (total == 0)
                  const SizedBox(
                    height: 160,
                    child: Center(
                      child: Text('No expenses in the last 12 months.'),
                    ),
                  )
                else
                  Semantics(
                    label: 'Monthly spending for the last 12 months',
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _TrendPainter(
                          values,
                          scheme.primary,
                          scheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: months
                      .map(
                        (month) => Expanded(
                          child: Text(
                            DateFormat('MMM').format(month),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What changed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (total > 0)
            card(
              Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      change > 0 ? Icons.trending_up : Icons.trending_down,
                      color: change > 0 ? scheme.error : scheme.primary,
                    ),
                    title: Text(
                      change > 0
                          ? 'Above your average'
                          : change < 0
                          ? 'Below your average'
                          : 'At your average',
                    ),
                    subtitle: Text(
                      '${DateFormat('MMMM').format(now)} is ${change.abs().toStringAsFixed(1)}% ${change < 0 ? 'below' : 'above'} your 12-month average. Current month is still in progress.',
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.arrow_upward),
                    title: const Text('Highest month'),
                    subtitle: Text(
                      '${DateFormat('MMMM yyyy').format(months[highest])} · ${money(values[highest])}',
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.arrow_downward),
                    title: const Text('Lowest month'),
                    subtitle: Text(
                      '${DateFormat('MMMM yyyy').format(months[lowest])} · ${money(values[lowest])}',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color gridColor;
  _TrendPainter(this.values, this.color, this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.reduce(math.max);
    if (maxValue <= 0) return;
    const inset = 6.0;
    final bottom = size.height - inset;
    for (var i = 0; i < 4; i++) {
      final y = inset + (bottom - inset) * i / 3;
      canvas.drawLine(
        Offset(inset, y),
        Offset(size.width - inset, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 0.5,
      );
    }
    final points = List.generate(
      values.length,
      (i) => Offset(
        inset + i * (size.width - inset * 2) / (values.length - 1),
        bottom - values[i] / maxValue * (bottom - inset),
      ),
    );
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final area = Path.from(line)
      ..lineTo(points.last.dx, bottom)
      ..lineTo(points.first.dx, bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.01),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => true;
}
