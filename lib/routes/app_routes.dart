// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_search_oficial/cubit/category_cubit.dart';
import 'package:job_search_oficial/screens/home_screen.dart';
import 'package:job_search_oficial/screens/login_screen.dart';
import 'package:job_search_oficial/screens/onboarding_screen.dart';
import 'package:job_search_oficial/screens/register_screen.dart';
import 'package:job_search_oficial/screens/splash_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String splash = '/splash';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        splash: (context) => const SplashRouterScreen(),
        register: (context) => const RegisterScreen(),
        home: (context) => MultiBlocProvider(providers: [
          BlocProvider(create: (_) => CategoryCubit()),
        ], child: const HomeScreen()),
        onboarding: (context) => const OnboardingScreen(),
      };
}
