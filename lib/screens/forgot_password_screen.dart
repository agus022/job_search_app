import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:job_search_oficial/core/constants/text_styles.dart';
import 'package:job_search_oficial/core/constants/colors.dart';
import 'package:job_search_oficial/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? generatedCode;
  String? enteredCode;

  bool showVerificationSection = false;
  bool codeVerified = false;

  String generateVerificationCode() {
    final random = Random();
    return List.generate(5, (_) => random.nextInt(10)).join();
  }

  void sendCode() {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un correo válido')),
      );
      return;
    }

    setState(() {
      generatedCode = generateVerificationCode();
      showVerificationSection = true;
      codeVerified = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Código enviado a $email')),
    );
  }

  void verifyCode() {
    if (enteredCode == generatedCode) {
      setState(() {
        codeVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Código correcto! Ahora cambia tu contraseña')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código incorrecto')),
      );
    }
  }

  void resetPassword() {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa ambos campos')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    // Aquí puedes hacer el cambio real en la base de datos (simulación):
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña actualizada exitosamente simulado')),
    );
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        title: const Text("Recuperar contraseña"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Correo electrónico", style: AppTextStyles.formLabel),
            const SizedBox(height: 8),
            CustomTextField(
              hintText: "Ingresa tu correo",
              controller: emailController,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Enviar código", style: AppTextStyles.buttonLogin),
              ),
            ),
            const SizedBox(height: 32),

            if (showVerificationSection) ...[
              Text("Código enviado: $generatedCode", style: AppTextStyles.body),
              const SizedBox(height: 16),
              PinCodeTextField(
                appContext: context,
                length: 5,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.grey.shade200,
                  inactiveColor: Colors.grey,
                  activeColor: Colors.blue,
                  selectedColor: Colors.blueAccent,
                ),
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
                onChanged: (value) {
                  setState(() => enteredCode = value);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Verificar código", style: AppTextStyles.buttonLogin),
                ),
              ),
            ],

            // Campos de nueva contraseña solo si el código fue verificado
            if (codeVerified) ...[
              const SizedBox(height: 32),
              Text("Nueva contraseña", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Ingresa nueva contraseña",
                controller: newPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              Text("Confirmar contraseña", style: AppTextStyles.formLabel),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: "Confirma la contraseña",
                controller: confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Cambiar contraseña", style: AppTextStyles.buttonLogin),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
