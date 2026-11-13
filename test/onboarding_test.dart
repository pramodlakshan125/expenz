import 'package:expenz/screens/onboarding/first_launch_gate.dart';
import 'package:expenz/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FirstLaunchGate(
          builder: (_) => const Scaffold(body: Text('Auth destination')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'first launch shows onboarding and skipping persists across launches',
    (tester) async {
      await open(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Auth destination'), findsNothing);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(find.text('Auth destination'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool('onboarding_completed'),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await open(tester);
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('Auth destination'), findsOneWidget);
    },
  );

  testWidgets('finishing all pages marks onboarding complete', (tester) async {
    await open(tester);
    for (var page = 0; page < 2; page++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Auth destination'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool('onboarding_completed'),
      isTrue,
    );
  });

  testWidgets('closing unfinished onboarding shows it on the next launch', (
    tester,
  ) async {
    await open(tester);
    await tester.pumpWidget(const SizedBox());
    await open(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
