import 'package:expenz/constant/colors.dart';
import 'package:expenz/screens/home_screen.dart';
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
  // Which tab is open: 0 = Home, 1 = Planner, 2 = Analytics, 3 = Profile
  int _currentIndex = 0;

  // Same order as the tabs in the nav bar
  final List<Widget> _pages = const [
    HomeScreen(),
    //PlannerScreen(),
    //AnalyticsScreen(),
    Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Shows only the page at _currentIndex, keeps the others alive
      body: IndexedStack(index: _currentIndex, children: _pages),

      // Round green button in the middle of the bar
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Next step: open the Add screen here
        },
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // The dark bar with the 4 tabs (lives in widgets/custom_bottom_nav.dart)
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
