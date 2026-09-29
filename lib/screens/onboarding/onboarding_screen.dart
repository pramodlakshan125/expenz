import 'package:expenz/constant/colors.dart';
import 'package:expenz/data/onboarding_data.dart';
import 'package:expenz/screens/onboarding/shared_onboardind_screen.dart';
import 'package:expenz/screens/user_login_screen.dart';
import 'package:expenz/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  //page controller for pageview
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool showDetailsPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F9),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                //onboard
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      showDetailsPage = index == 2;
                    });
                  },
                  children: [
                    SharedOnboardindScreen(
                      title: OnboardingData.onboardingDataList[0].title,
                      imagePath: OnboardingData.onboardingDataList[0].imagePath,
                      description:
                          OnboardingData.onboardingDataList[0].description,
                    ),
                    SharedOnboardindScreen(
                      title: OnboardingData.onboardingDataList[1].title,
                      imagePath: OnboardingData.onboardingDataList[1].imagePath,
                      description:
                          OnboardingData.onboardingDataList[1].description,
                    ),
                    SharedOnboardindScreen(
                      title: OnboardingData.onboardingDataList[2].title,
                      imagePath: OnboardingData.onboardingDataList[2].imagePath,
                      description:
                          OnboardingData.onboardingDataList[2].description,
                    ),
                  ],
                ),

                //page indicator
                Container(
                  alignment: const Alignment(0, 0.6),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: OnboardingData.onboardingDataList.length,
                    effect: const WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: Color(0xFF25A67D),
                      dotColor: Colors.grey,
                    ),
                  ),
                ),

                //navigation button
                Positioned(
                  bottom: 25,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: !showDetailsPage
                        ? GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                _pageController.page!.toInt() + 1,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: CustomButton(
                              buttonName: "Next",
                              buttonColor: AppColors.primary,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              //navigate to the user data screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserLoginScreen(),
                                ),
                              );
                            },
                            child: CustomButton(
                              buttonName: "Get Start",
                              buttonColor: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                //Skip button
                if (!showDetailsPage)
                  Positioned(
                    top: 70,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserLoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
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
