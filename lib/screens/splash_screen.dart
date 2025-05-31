// lib/screens/splash_router_screen.dart
import 'package:flutter/material.dart';
import 'package:job_search_oficial/core/services/shared_prefs_service.dart';
import 'package:job_search_oficial/routes/app_routes.dart';

class SplashRouterScreen extends StatefulWidget {
  const SplashRouterScreen({super.key});

  @override
  State<SplashRouterScreen> createState() => _SplashRouterScreenState();
}

class _SplashRouterScreenState extends State<SplashRouterScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 500)); // opcional
    final isFirstTime = SharedPrefsService.isFirstLaunch;

    Navigator.pushReplacementNamed(
      context,
      isFirstTime ? AppRoutes.onboarding : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
