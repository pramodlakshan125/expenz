import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';

class FirstLaunchGate extends StatefulWidget {
  final WidgetBuilder builder;
  const FirstLaunchGate({super.key, required this.builder});
  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  bool? _completed;
  bool _loadFailed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _completed = preferences.getBool('onboarding_completed') ?? false;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _complete() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool('onboarding_completed', true)) {
      throw StateError('Could not save onboarding.');
    }
    if (mounted) setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: _load,
            child: const Text('Retry opening app'),
          ),
        ),
      );
    }
    if (_completed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_completed!) return OnboardingScreen(onComplete: _complete);
    return widget.builder(context);
  }
}
