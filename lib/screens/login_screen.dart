import 'package:cloud_firestore/cloud_firestore.dart';
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
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot_password');
                    },
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
                  onPressed: () async {

                    final email = nameController.text.trim();
                    final password = passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, completa todos los campos')),
                      );
                      return;
                    }
                    await userCubit.login(email, password);


                    if (userCubit.state.status == UserStatus.logged) {
                      final user = userCubit.state.user!;
                      final userId = user.id;

                      if (userId != null) {
                        checkActiveService(
                            context, userId, user.type == 'official');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User ID is null')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(userCubit.state.error ?? 'Login fallido')),
                      );
                    }
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

  Future<void> checkActiveService(
      BuildContext context, String userId, bool isOficial) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    final serviceId = userDoc.data()?['activeService'];
    final role = userDoc.data()?['role'];

    if (serviceId != null && serviceId != '') {
      final serviceDoc = await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .get();

      if (serviceDoc.exists) {
        final data = serviceDoc.data()!;
        final state = data['state'];
        final clientConfirmed = data['clientConfirmed'] == true;
        final oficialConfirmed = data['oficialConfirmed'] == true;

        if (state == 'accepted' && clientConfirmed && oficialConfirmed) {
          Navigator.pushReplacementNamed(context, '/live_tracking', arguments: {
            'serviceId': serviceId,
            'isOficial': role == 'oficial',
          });
        } else if (state == 'pending' ||
            !(clientConfirmed && oficialConfirmed)) {
          Navigator.pushReplacementNamed(
            context,
            '/waiting_confirmation',
            arguments: {
              'serviceId': serviceId,
            },
          );
        } else {
          // si el estado es cancelado o completado
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'activeService': null});
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}
