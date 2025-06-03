import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:http/http.dart' as http;


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
  final addressController = TextEditingController();
  

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

  Future<String> uploadImageToCloudinary(File imageFile, String userId) async {
    const cloudName = 'dejfghad3'; 
    const uploadPreset = 'oficiales_job'; 

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['public_id'] = 'profile_pictures/$userId';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decoded = json.decode(responseBody);
      return decoded['secure_url'];
    } else {
      throw Exception('Error al subir imagen a Cloudinary');
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
                          : const AssetImage('assets/img/default_avatar3.png')
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
              const SizedBox(height: 8),
              Text(
                "Your photo will only be visible for use within the app. It won't be shared publicly",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
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
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 16),

              // Address
              Text("Address", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Enter your address (#, street, city, state, zip code)", 
                controller: addressController,
              ),
              const SizedBox(height: 4),
              Text(
                "The address will only be visible to people with whom a service is established.",
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
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
                    String profilePictureUrl = 'https://asset.cloudinary.com/dejfghad3/526956abdff0d7f426fa707ee082564b';
                    //obtener valores de los campos de texto sin espacios en blanco .trim es lo q hace  
                    final name = nameController.text.trim();
                    final lastName = lastNameController.text.trim();
                    final phone = phoneController.text.trim();
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    final confirmPassword = confirmPasswordController.text.trim();
                    final address = addressController.text.trim();

                    final Map<String, String> fieldLabels = {
                      'name': nameController.text.trim(),
                      'last name': lastNameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'email': emailController.text.trim(),
                      'password': passwordController.text.trim(),
                      'confirm password': confirmPasswordController.text.trim(),
                      'address': addressController.text.trim(),
                    };

                    // Busca el primer campo vacío
                    final missingField = fieldLabels.entries.firstWhere(
                      (entry) => entry.value.isEmpty,
                      orElse: () => const MapEntry('', ''),
                    );

                    // Si falta algún campo, muestra mensaje específico
                    if (missingField.key.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('El campo "${missingField.key}" es obligatorio.')),
                      );
                      return;
                    }

                    // validar campos no sean vacios
                    final values = [name, lastName, phone, email, password, confirmPassword, address];
                    if (values.any((e) => e.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Todos los campos son obligatorios')),);
                      return;
                    }
                    //validar coincidencia con contraseñas
                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Las contraseñas no coinciden')),
                      );
                      return;
                    }

                    if (_selectedImage != null) {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        profilePictureUrl = await uploadImageToCloudinary(_selectedImage!, userId);
                      }
                    }


                    userCubit.registerClient(
                      name: name,
                      lastName: lastName,
                      email: email,
                      password: password,
                      phone: phone,
                      profilePicture: profilePictureUrl,
                      address: address,
                    );

                      if (userCubit.state.status == UserStatus.uncofirmmed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registro exitoso. Revisa tu correo.')),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(userCubit.state.error ?? 'Error al registrarse')),
                        );
                      }

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
