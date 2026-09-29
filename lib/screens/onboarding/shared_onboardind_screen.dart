import 'package:expenz/constant/colors.dart';
import 'package:flutter/material.dart';

class SharedOnboardindScreen extends StatelessWidget {
  final String title;
  final String imagePath;
  final String description;

  const SharedOnboardindScreen({
    super.key,
    required this.title,
    required this.imagePath,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 70),

        Align(
          alignment: Alignment.center,
          child: Image.asset(
            imagePath,
            width: 400,
            height: 400,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 30),

        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
