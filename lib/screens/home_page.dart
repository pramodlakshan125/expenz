import 'package:expenz/widgets/nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:expenz/constant/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: NavBar()));
  }
}
