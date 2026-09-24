import 'package:expenz/screens/onboarding/front_page.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                //onboard
                PageView(
                  children: [
                    const FrontPage(),

                    Container(color: Colors.green),
                    Container(color: Colors.yellow),
                    Container(color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
