import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/screens/add_new_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> open(
    WidgetTester tester,
    Future<void> Function(TransactionModel) save, {
    TransactionType type = TransactionType.expense,
    bool dark = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: AddNewPage(initialType: type, onSave: save),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder getSave(String label) => find.widgetWithText(FilledButton, label);
  Future<void> fill(WidgetTester tester, String category) async {
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'Lunch with team');
    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, '1200.50');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(category));
    await tester.pumpAndSettle();
    await tester.tap(find.text(category));
    await tester.pumpAndSettle();
  }

  testWidgets('validates amount and saves a selected earlier day', (
    tester,
  ) async {
    final saved = <TransactionModel>[];
    await open(tester, (transaction) async => saved.add(transaction));
    await tester.tap(getSave('Add expense'));
    await tester.pump();
    await tester.ensureVisible(find.text('Enter an amount greater than zero.'));
    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Previous month'));
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, '1'));
    final now = DateTime.now();
    final expected = DateTime(now.year, now.month - 1, 1);
    await fill(tester, 'Food & Dining');
    await tester.tap(getSave('Add expense'));
    await tester.pumpAndSettle();
    expect(saved, hasLength(1));
    expect(saved.single.amount, 1200.50);
    expect(saved.single.title, 'Lunch with team');
    expect(saved.single.type, TransactionType.expense);
    expect(DateUtils.dateOnly(saved.single.date), expected);
    expect(find.text('Transaction saved'), findsOneWidget);
  });
  testWidgets('blocks future days and next month in night mode', (
    tester,
  ) async {
    await open(tester, (_) async {}, dark: true);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Next month',
            ),
          )
          .onPressed,
      isNull,
    );
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    for (var day = now.day + 1; day <= days; day++) {
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '$day'))
            .onPressed,
        isNull,
      );
    }
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '${now.day}'))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('income uses income categories and saves today', (tester) async {
    TransactionModel? saved;
    await open(tester, (value) async {
      saved = value;
    }, type: TransactionType.income);
    expect(find.text('Food & Dining'), findsNothing);
    await fill(tester, 'Salary');
    await tester.tap(getSave('Add income'));
    await tester.pumpAndSettle();
    expect(saved!.isIncome, isTrue);
    expect(DateUtils.isSameDay(saved!.date, DateTime.now()), isTrue);
  });
  testWidgets('failed save retains input for retry', (tester) async {
    var attempts = 0;
    await open(tester, (_) async {
      if (attempts++ == 0) throw Exception('offline');
    });
    await fill(tester, 'Transport');
    await tester.tap(getSave('Add expense'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      '1200.50',
    );
    await tester.tap(getSave('Add expense'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction saved'), findsOneWidget);
    expect(attempts, 2);
  });
  testWidgets(
    'custom categories persist and require a two second hold to delete',
    (tester) async {
      await open(tester, (_) async {});
      final add = find.bySemanticsLabel('Add category');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Category name'),
        'Daily coffee',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Add'));
      await tester.pumpAndSettle();
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          'categories.expense',
        ),
        contains('Daily coffee'),
      );
      final chip = find.widgetWithText(ChoiceChip, 'Daily coffee');
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(chip));
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.text('Delete "Daily coffee"?'), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Delete "Daily coffee"?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Daily coffee'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          'categories.expense',
        ),
        isNot(contains('Daily coffee')),
      );
    },
  );
}
