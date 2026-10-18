import 'package:flutter/material.dart';

class Analyze extends StatefulWidget {
  const Analyze({super.key});

  @override
  State<Analyze> createState() => _AnalyzeState();
}

class _AnalyzeState extends State<Analyze> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Analyze Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
