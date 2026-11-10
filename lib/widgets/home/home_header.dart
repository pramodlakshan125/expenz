import 'package:expenz/constant/colors.dart';
import 'package:expenz/constant/app_icons.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final bool hasNotification;
  final VoidCallback? onBellTap;

  const HomeHeader({
    super.key,
    required this.userName,
    this.hasNotification = false,
    this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back 👋',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onBellTap,
          customBorder: const CircleBorder(),
          child: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F0EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Icon(AppIcons.bell, color: Color(0xFF007F61)),
              ),
              if (hasNotification)
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
