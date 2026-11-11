import 'package:expenz/models/transaction_model.dart';
import 'package:expenz/services/transaction_service.dart';
import 'package:expenz/constant/colors.dart';
import 'package:expenz/screens/add_new_page.dart';
import 'package:expenz/screens/analytics_screen.dart';
import 'package:expenz/screens/home_screen.dart';
import 'package:expenz/screens/goals_page.dart';
import 'package:expenz/screens/profile.dart';
import 'package:expenz/screens/transaction_page.dart';
import 'package:expenz/widgets/costom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

/// The "shell": holds the bottom nav bar, the round middle button,
/// and shows one tab page at a time.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Which tab is open: 0 = Home, 1 = Transactions, 2 = Analytics, 3 = Profile
  int _currentIndex = 0;

  late var _transactions = TransactionService().watch();

  void _retryTransactions() {
    setState(() => _transactions = TransactionService().watch());
  }

  Widget _transactionError(Object error) {
    final message = switch (error) {
      FirebaseException(code: 'permission-denied') =>
        'Your account cannot access transactions. Check the Firestore access rules.',
      FirebaseException(code: 'unauthenticated') =>
        'Your session has expired. Please sign in again.',
      FirebaseException(code: 'unavailable') =>
        'Transactions are temporarily unavailable. Check your connection and try again.',
      _ => 'Could not load transactions. Please try again.',
    };
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _retryTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _add([TransactionType type = TransactionType.expense]) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => AddNewPage(initialType: type)),
    );
  }

  // Same order as the tabs in the nav bar.

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Transaction stream failed: ${snapshot.error}');
        }
        final transactions = snapshot.data ?? const <TransactionModel>[];
        //screen list
        final List<Widget> pages = [
          snapshot.hasError
              ? _transactionError(snapshot.error!)
              : snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : HomeScreen(
                  transactions: transactions,
                  onAddExpense: () => _add(),
                  onAddIncome: () => _add(TransactionType.income),
                  onSeeAll: () => setState(() => _currentIndex = 1),
                  onInsights: () => setState(() => _currentIndex = 2),
                  onGoals: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const GoalsPage()),
                  ),
                ),
          TransactionPage(
            transactions: transactions,
            loading: snapshot.connectionState == ConnectionState.waiting,
            hasError: snapshot.hasError,
          ),
          AnalyticsScreen(),
          Profile(),
        ];
        return Scaffold(
          // Shows only the page at _currentIndex, keeps the others alive
          body: IndexedStack(index: _currentIndex, children: pages),

          // Round button in the middle of the bar
          floatingActionButton: FloatingActionButton(
            onPressed: () => _add(),
            shape: const CircleBorder(),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,

          // The bar with the 4 tabs (lives in widgets/costom_nav_bar.dart)
          bottomNavigationBar: CustomBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        );
      },
    );
  }
}
