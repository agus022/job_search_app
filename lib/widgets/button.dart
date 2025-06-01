import 'package:flutter/material.dart';
import 'package:job_search_oficial/core/constants/colors.dart';
import 'package:job_search_oficial/core/constants/text_styles.dart';

class SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String? iconPath; // Opcional

  const SocialButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = iconPath != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Image.asset(
              iconPath!,
              width: 24,
              height: 24,
            ),
            label: Text(
              label,
              style: AppTextStyles.button,
            ),
            style: _buttonStyle,
          )
        : ElevatedButton(
            onPressed: onPressed,
            child: Text(
              label,
              style: AppTextStyles.button,
            ),
            style: _buttonStyle,
          );

    return buttonChild;
  }

  ButtonStyle get _buttonStyle => ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.black26,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppColors.borderButton,
            width: 1.5,
          ),
        ),
      ).copyWith(
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return const Color.fromARGB(30, 102, 102, 102);
            }
            return null;
          },
        ),
      );
}
