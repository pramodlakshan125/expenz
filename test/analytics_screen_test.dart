import 'package:expenz/screens/analytics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens category details and returns to the breakdown', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AnalyticsScreen())));
    expect(find.text('Insights'), findsOneWidget);
    await tester.tap(find.text('See all'));
    await tester.pump();
    expect(find.text('Spending by category'), findsOneWidget);
    await tester.tap(find.text('List view'));
    await tester.pump();
    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(find.text('Average'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to insights'));
    await tester.pump();
    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('List view'), findsOneWidget);
  });

  testWidgets('shows an empty state for a future year', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AnalyticsScreen())));
    await tester.tap(find.text('Year'));
    await tester.pump();
    await tester.tap(find.byTooltip('Next period'));
    await tester.pump();
    expect(find.text('No expenses in this period.'), findsOneWidget);
    expect(find.text('Rs. 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
