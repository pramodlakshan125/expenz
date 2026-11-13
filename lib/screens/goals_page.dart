import 'package:flutter/material.dart';
import 'package:expenz/widgets/goals/goals_section.dart';

export 'package:expenz/widgets/goals/goals_section.dart' show GoalsSection;

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Goals')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: GoalsSection(),
    ),
  );
}
