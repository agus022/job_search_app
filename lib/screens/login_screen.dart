import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_search_oficial/core/constants/colors.dart';
import 'package:job_search_oficial/core/constants/text_styles.dart';
import 'package:job_search_oficial/widgets/button.dart';
import 'package:job_search_oficial/widgets/custom_text_field.dart';

import '../cubit/user_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool showPassword = false;

  final nameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userCubit = context.read<UserCubit>();

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Sign In", style: AppTextStyles.headline),
              const SizedBox(height: 6),
              Text("Welcome back you’ve been missed",
                  style: AppTextStyles.body),
              const SizedBox(height: 32),

              // Email
              Text("Email", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter Email",
                controller: nameController,
              ),

              const SizedBox(height: 16),

              // Password
              Text("Password", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter your password",
                controller: passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 12),

              // Remember Me + Forgot
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text("Forgot Password?",
                        style: AppTextStyles.hightLightText
                            .copyWith(decoration: TextDecoration.underline)),
                  )
                ],
              ),

              const SizedBox(height: 20),

              // Sign In button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    userCubit.login('21030761@itcelaya.edu.mx', 'panquecito');
                    if (userCubit.state.status == UserStatus.logged) {
                      Navigator.pushNamed(context, '/home');
                    }
                    // TODO: Mostrar logged failed
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Sign In", style: AppTextStyles.buttonLogin),
                ),
              ),
              const SizedBox(height: 24),

              // Divider with "Or with"
              Row(
                children: [
                  const Expanded(
                      child: Divider(
                    color: AppColors.borderButton,
                    thickness: 1.5,
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Or with", style: AppTextStyles.body),
                  ),
                  const Expanded(
                      child: Divider(
                    color: AppColors.borderButton,
                    thickness: 1.5,
                  )),
                ],
              ),
              const SizedBox(height: 20),

              // Social buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SocialButton(
                    label: "Continue with Google",
                    iconPath: 'assets/icons/google_logo.png',
                    onPressed: () {
                      // Acción con Google
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Bottom text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: AppTextStyles.body),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text("Sign Up",
                        style: AppTextStyles.hightLightText.copyWith(
                          decoration: TextDecoration.underline,
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
