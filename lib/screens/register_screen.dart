import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:job_search_oficial/core/constants/colors.dart';
import 'package:job_search_oficial/core/constants/text_styles.dart';
import 'package:job_search_oficial/widgets/custom_text_field.dart';
import '../cubit/cubits.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool showPassword = false;
  bool showConfirmPassword = false;

  final nameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage({bool fromCamera = false}) async {
    final pickedFile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

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
              Text("Sign Up", style: AppTextStyles.headline),
              const SizedBox(height: 6),
              Text("Create your new account", style: AppTextStyles.body),
              const SizedBox(height: 32),

              // Avatar selector
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : const AssetImage('assets/img/default_avatar.png')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 1,
                      right: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white70,
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 20, color: Colors.black87),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (_) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading: const Icon(Icons.photo),
                                    title: Text('Seleccionar de galería',
                                        style: AppTextStyles.body),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(fromCamera: false);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: Text(
                                      'Tomar una foto',
                                      style: AppTextStyles.body,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(fromCamera: true);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Name
              Text("Name", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter your name",
                controller: nameController,
              ),
              const SizedBox(height: 16),

              // Last Name
              Text("Last Name", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter your last name",
                controller: lastNameController,
              ),
              const SizedBox(height: 16),

              // Phone
              Text("Phone", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter your phone number",
                controller: phoneController,
              ),
              const SizedBox(height: 16),

              // Email
              Text("Email", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter your email",
                controller: emailController,
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

              const SizedBox(height: 16),

              // Confirm password
              Text("Confirm Password", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Confirm your password",
                controller: confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 28),

              // Sign Up button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    String? base64Image;
                    if (_selectedImage != null) {
                      final bytes = await _selectedImage!.readAsBytes();
                      base64Image = base64Encode(bytes);
                    }

                    userCubit.registerClient(
                      name: nameController.text,
                      lastName: '',
                      email: emailController.text,
                      password: passwordController.text,
                      phone: '',
                      profilePicture: base64Image ?? '',
                      address: '',
                    );

                    print('Error: ${userCubit.state.error}');
                    print('Message: ${userCubit.state.message}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Sign Up", style: AppTextStyles.buttonLogin),
                ),
              ),
              const SizedBox(height: 32),

              // Bottom text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?", style: AppTextStyles.body),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text("Sign In",
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
