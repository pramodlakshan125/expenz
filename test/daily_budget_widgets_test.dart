import 'package:expenz/constant/colors.dart';
import 'package:expenz/models/budget_ledger.dart';
import 'package:expenz/models/daily_budget_settings.dart';
import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/models/wallet_entry.dart';
import 'package:expenz/services/budget_controller.dart';
import 'package:expenz/services/daily_budget_calculator.dart';
import 'package:expenz/widgets/home/balance_card.dart';
import 'package:expenz/widgets/home/balance_correction_sheet.dart';
import 'package:expenz/widgets/home/daily_limit_sheet.dart';
import 'package:expenz/widgets/home/daily_progress_bar.dart';
import 'package:expenz/widgets/home/settlement_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_budget_repository.dart';

void main() {
  testWidgets('balance correction previews the missing expense before saving', (
    tester,
  ) async {
    final repository = FakeBudgetRepository();
    final controller = BudgetController(
      repository: repository,
      clock: () => DateTime(2026, 4, 2),
    )..start();
    repository.events.add(
      BudgetLedger(
        settings: null,
        transactions: [
          TransactionModel(
            id: 'income',
            title: 'Opening funds',
            category: 'Other',
            amount: 10000,
            date: DateTime(2026, 4, 1),
            type: TransactionType.income,
          ),
        ],
        settlements: [],
        walletEntries: [],
        readyForSettlement: true,
        hasPendingWrites: false,
        isFromCache: false,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BalanceCorrectionSheet(controller: controller)),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), '8000');
    await tester.enterText(find.byType(TextFormField).at(1), '1000');
    await tester.tap(find.text('Review adjustment'));
    await tester.pump();
    expect(find.text('Unrecorded expense: Rs. 1,000'), findsOneWidget);
    expect(find.text('Confirm adjustment'), findsOneWidget);
    expect(controller.ledger!.transactions.length, 1);
    await tester.enterText(find.byType(TextFormField).at(0), '10000');
    await tester.pump();
    await tester.tap(find.text('Review adjustment'));
    await tester.pump();
    expect(find.text('Balance adjustment income: Rs. 1,000'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await repository.events.close();
  });

  testWidgets(
    'daily bar changes color at 70 and 100 percent and caps overspend',
    (tester) async {
      for (final sample in [
        (spent: 34999, color: AppColors.primary),
        (spent: 35000, color: AppColors.warningState),
        (spent: 49999, color: AppColors.warningState),
        (spent: 50000, color: AppColors.dangerState),
        (spent: 65000, color: AppColors.dangerState),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DailyProgressBar(
                spentMinor: sample.spent,
                limitMinor: 50000,
              ),
            ),
          ),
        );
        final progress = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progress.color, sample.color);
        expect(progress.value, (sample.spent / 50000).clamp(0.0, 1.0));
      }
      expect(find.text('Rs. 650 of Rs. 500 spent'), findsOneWidget);
      expect(find.text('Over by Rs. 150'), findsOneWidget);
    },
  );

  testWidgets('zero target has a safe empty bar without spending', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DailyProgressBar(spentMinor: 0, limitMinor: 0)),
      ),
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'daily balance card explains the reduction on a small dark screen',
    (tester) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final day = const DailyBudgetCalculator().calculate(
        settings: DailyBudgetSettings(
          dailyLimitMinor: 50000,
          startDate: DateTime(2026, 4, 1),
        ),
        day: DateTime(2026, 4, 21),
        transactions: [],
        carriedOverspendMinor: 80000,
        carriedMonth: DateTime(2026, 4),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(child: BalanceCard(daily: day)),
          ),
        ),
      );
      expect(
        find.textContaining('Your limit is Rs. 420 today'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('daily target rejects invalid precision and accepts cents', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DailyLimitSheet())),
    );
    await tester.enterText(find.byType(TextFormField), '500.001');
    await tester.tap(find.text('Save daily target'));
    await tester.pump();
    expect(
      find.text('Enter zero or a positive amount with up to 2 decimals.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'settlement asks before partial wallet coverage and blocks duplicate taps',
    (tester) async {
      final repository = FakeBudgetRepository();
      final controller = BudgetController(
        repository: repository,
        clock: () => DateTime(2026, 4, 2),
      )..start();
      repository.events.add(
        BudgetLedger(
          settings: DailyBudgetSettings(
            dailyLimitMinor: 50000,
            startDate: DateTime(2026, 4, 1),
          ),
          transactions: [
            TransactionModel(
              id: 'one',
              title: 'Food',
              category: 'Food',
              amount: 650,
              date: DateTime(2026, 4, 1),
              type: TransactionType.expense,
            ),
          ],
          settlements: [],
          walletEntries: [
            WalletEntry(
              relatedDay: '2026-03-31',
              date: DateTime(2026, 3, 31),
              amountMinor: 5000,
              type: WalletEntryType.deposit,
            ),
          ],
          readyForSettlement: true,
          hasPendingWrites: false,
          isFromCache: true,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettlementSheet(controller: controller)),
        ),
      );
      expect(find.text('Cover Rs. 50 from your wallet?'), findsOneWidget);
      expect(find.text('Rs. 100 will still be uncovered.'), findsOneWidget);
      expect(repository.savedDays, isEmpty);
      await tester.tap(find.text('Yes'));
      await tester.pump();
      expect(repository.savedDays.single.walletChangeMinor, -5000);
      expect(repository.savedDays.single.uncoveredMinor, 10000);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Yes'))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await repository.events.close();
    },
  );
}
