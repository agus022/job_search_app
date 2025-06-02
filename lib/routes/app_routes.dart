// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_search_oficial/cubit/category_cubit.dart';
import 'package:job_search_oficial/cubit/job_cubit.dart';
import 'package:job_search_oficial/entities/user.dart';
import 'package:job_search_oficial/screens/edit_partner_screen.dart';
import 'package:job_search_oficial/screens/home_screen.dart';
import 'package:job_search_oficial/screens/job_detail_screen.dart';
import 'package:job_search_oficial/screens/live_tracking_screen.dart';
import 'package:job_search_oficial/screens/login_screen.dart';
import 'package:job_search_oficial/screens/onboarding_screen.dart';
import 'package:job_search_oficial/screens/partner_screen.dart';
import 'package:job_search_oficial/screens/profile_detail_screen.dart';
import 'package:job_search_oficial/screens/register_screen.dart';
import 'package:job_search_oficial/screens/request_service_screen.dart';
import 'package:job_search_oficial/screens/splash_screen.dart';
import 'package:job_search_oficial/screens/waiting_for_confirmation_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String onboarding = '/onboarding';
  static const String jobdetail = '/job_detail';
  static const String profiledetail = '/profile_detail';
  static const String partner = '/partner';
  static const String requestservice = '/request_service';
  static const String livetracking = '/live_tracking';
  static const String splash = '/splash';
  static const String editpartner = '/edit_partner_profile';
  static const String waitingforconfirmation = '/waiting_confirmation';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        splash: (context) => const SplashRouterScreen(),
        register: (context) => const RegisterScreen(),
        home: (context) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => CategoryCubit()),
                BlocProvider(create: (_) => JobCubit()),
              ],
              child: const HomeScreen(),
            ),
        onboarding: (context) => const OnboardingScreen(),
        profiledetail: (context) => const ProfileScreen(),
        partner: (context) => MultiBlocProvider(providers: [
              BlocProvider(create: (_) => CategoryCubit()),
              BlocProvider(create: (_) => JobCubit())
            ], child: const PartnerScreen()),
        jobdetail: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as UserEntity;
          return JobDetailScreen(user: args);
        },
        requestservice: (context) => const RequestServiceScreen(),
        livetracking: (context) => const LiveTrackingScreen(),
        editpartner: (context) => MultiBlocProvider(providers: [
              BlocProvider(create: (_) => CategoryCubit()),
              BlocProvider(create: (_) => JobCubit())
            ], child: const EditPartnerProfileScreen()),
        waitingforconfirmation: (context) =>
            const WaitingForConfirmationScreen(),
      };
}
