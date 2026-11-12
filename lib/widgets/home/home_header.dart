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
    final name = userName.trim();
    final firstName = name.isEmpty
        ? 'Your account'
        : name.split(RegExp(r'\s+')).first;
    final initial = name.isNotEmpty ? firstName[0].toUpperCase() : '?';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning!'
        : hour < 17
        ? 'Good afternoon!'
        : 'Good evening!';
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 2),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onBellTap,
          customBorder: CircleBorder(),
          child: Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Icon(AppIcons.bell, color: AppColors.primary),
              ),
              if (hasNotification)
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
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
