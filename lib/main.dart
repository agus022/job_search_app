import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:job_search_oficial/firebase_options.dart';
import 'package:job_search_oficial/screens/home_screen.dart';
import 'package:job_search_oficial/screens/login_screen.dart';
import 'package:job_search_oficial/screens/register_screen.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
