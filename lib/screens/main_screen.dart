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

  late final _transactions = TransactionService().watch();

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
        final transactions = snapshot.data ?? const <TransactionModel>[];
        //screen list
        final List<Widget> pages = [
          snapshot.hasError
              ? const SafeArea(
                  child: Center(
                    child: Text(
                      'Could not load transactions. Check your connection.',
                    ),
                  ),
                )
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
