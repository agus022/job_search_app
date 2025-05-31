import 'package:flutter/material.dart';
import 'package:job_search_oficial/core/constants/app_theme.dart';
import 'package:job_search_oficial/core/services/shared_prefs_service.dart';
import 'package:job_search_oficial/routes/app_routes.dart';

class JobSearchApp extends StatelessWidget {
  const JobSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      title: 'Job Search',
      initialRoute: SharedPrefsService.isFirstLaunch
          ? AppRoutes.onboarding
          : AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
