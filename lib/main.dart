import 'package:expenz/auth/login.dart';
import 'package:expenz/screens/home_page.dart';
import 'package:expenz/screens/onboarding/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expenz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "Inter"),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. If Firebase finds a saved user on the phone -> Go to Home Page!
          if (snapshot.hasData) {
            return const HomePage();
          }

          // 2. If NO user is saved -> Go to Login Page!
          return const LogIn();
        },
      ),
    );
  }
}
