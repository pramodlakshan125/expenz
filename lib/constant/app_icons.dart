import 'package:flutter/material.dart';

/// Shared filled icons and category colors matching the app's visual language.
abstract final class AppIcons {
  static const wallet = Icons.account_balance_wallet;
  static const income = Icons.file_download;
  static const money = Icons.attach_money;
  static const food = Icons.local_cafe;
  static const transport = Icons.directions_bus;
  static const shopping = Icons.shopping_cart;
  static const health = Icons.add;
  static const bills = Icons.flash_on;
  static const entertainment = Icons.movie;
  static const gift = Icons.card_giftcard;
  static const plane = Icons.flight;
  static const laptop = Icons.laptop;
  static const plus = Icons.add;
  static const search = Icons.search;
  static const filter = Icons.filter_list;
  static const repeat = Icons.repeat;
  static const note = Icons.edit;
  static const calendar = Icons.event;
  static const calendarAlt = Icons.calendar_today;
  static const document = Icons.description;
  static const grid = Icons.grid_view;
  static const check = Icons.check;
  static const close = Icons.close;
  static const trash = Icons.delete;
  static const logout = Icons.logout;
  static const bell = Icons.notifications;
  static const eye = Icons.visibility;
  static const lock = Icons.lock;
  static const shield = Icons.shield;
  static const warning = Icons.warning;
  static const help = Icons.help;
  static const idea = Icons.lightbulb;
  static const globe = Icons.language;
  static const phone = Icons.phone;
  static const star = Icons.star;
  static const arrowUp = Icons.arrow_upward;
  static const arrowDown = Icons.arrow_downward;
  static const arrowRight = Icons.arrow_forward;
  static const chevronRight = Icons.chevron_right;
  static const chevronLeft = Icons.chevron_left;

  static IconData category(String name) => switch (name.toLowerCase()) {
    'food' || 'food & dining' => food,
    'transport' => transport,
    'shopping' => shopping,
    'health' => health,
    'bills' || 'bills & utilities' => bills,
    'entertainment' => entertainment,
    'gift' || 'gifts' => gift,
    'travel' || 'plane' => plane,
    'laptop' || 'technology' => laptop,
    'salary' || 'income' => income,
    'money' || 'savings' => money,
    'wallet' => wallet,
    _ => document,
  };

  static Color categoryColor(String name) => switch (category(name)) {
    food => const Color(0xFFCA7029),
    transport || plane => const Color(0xFF5E77AE),
    shopping => const Color(0xFF70794B),
    health => const Color(0xFFD9AF16),
    bills || laptop => const Color(0xFF3C4C52),
    entertainment || gift => const Color(0xFF8D608C),
    _ => const Color(0xFF007F61),
  };
}

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;
  final double iconSize;
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 46,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppIcons.categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        shape: BoxShape.circle,
      ),
      child: Icon(AppIcons.category(category), color: color, size: iconSize),
    );
  }
}
