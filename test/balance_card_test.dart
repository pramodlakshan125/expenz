import 'package:expenz/constant/colors.dart';
import 'package:expenz/widgets/home/balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBalanceCard(
    WidgetTester tester, {
    required double spentAmount,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BalanceCard(spentAmount: spentAmount, monthlyBudget: 500000),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a green progress line while spending is on track', (
    tester,
  ) async {
    await pumpBalanceCard(tester, spentAmount: 100000);

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    final expectedColor = Color.lerp(
      AppColors.safeState,
      AppColors.warningState,
      0.2 / 0.7,
    );

    expect(find.text('ON TRACK'), findsOneWidget);
    expect(progress.value, 0.2);
    expect(progress.valueColor!.value!.toARGB32(), expectedColor!.toARGB32());
    expect(find.text('Rs. 400,000 left'), findsOneWidget);
  });

  testWidgets('shifts the progress line toward red near the budget limit', (
    tester,
  ) async {
    await pumpBalanceCard(tester, spentAmount: 400000);

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    final expectedColor = Color.lerp(
      AppColors.warningState,
      AppColors.dangerState,
      1 / 3,
    );

    expect(find.text('NEAR LIMIT'), findsOneWidget);
    expect(progress.value, 0.8);
    expect(progress.valueColor!.value!.toARGB32(), expectedColor!.toARGB32());
  });

  testWidgets('caps the line and explains how far spending exceeds budget', (
    tester,
  ) async {
    await pumpBalanceCard(tester, spentAmount: 525000);

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    expect(find.text('OVER BUDGET'), findsOneWidget);
    expect(progress.value, 1);
    expect(
      progress.valueColor!.value!.toARGB32(),
      AppColors.dangerState.toARGB32(),
    );
    expect(find.text('Over by Rs. 25,000'), findsOneWidget);
    expect(
      find.text("You're over budget. Review your spending plan."),
      findsOneWidget,
    );
  });
}
