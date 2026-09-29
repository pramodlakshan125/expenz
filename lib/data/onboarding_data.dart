import 'package:expenz/models/onbording_model.dart';

class OnboardingData {
  static final List<OnboardingModel> onboardingDataList = [
    OnboardingModel(
      title: "Smart Daily Spending Limits",
      imagePath: "assets/images/onboarding1.png",
      description:
          "Set your monthly target and let Expenz calculate the exact amount  you can spend each day to stay on track.",
    ),
    OnboardingModel(
      title: "Schedule Bills & Save More",
      imagePath: "assets/images/onboarding2.png",
      description:
          "Lock in your fixed monthly bills first. We automatically adjust your remaining daily budget so you can save effortlessly.",
    ),
    OnboardingModel(
      title: "Clear Insights & Analytics",
      imagePath: "assets/images/onboarding3.png",
      description:
          "Track every income and outcome in real time with dynamic color alerts and comprehensive financial summaries.",
    ),
  ];
}
