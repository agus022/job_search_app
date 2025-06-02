import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  static final TextStyle headline = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color.fromARGB(255, 0, 0, 0),
  );

  static final TextStyle body = GoogleFonts.poppins(
    fontSize: 16,
    color: AppColors.textLight,
  );

  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color.fromARGB(255, 0, 0, 0),
  );

  static final TextStyle buttonLogin = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static final TextStyle subtitle = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.textLight,
  );

  static final TextStyle formLabel = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static final TextStyle formHint = GoogleFonts.dmSans(
    fontSize: 16,
    color: Color(0xFFcacaca),
  );

  static final TextStyle hightLightText = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: const Color.fromARGB(255, 10, 10, 10),
  );

  static final TextStyle error = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.error,
  );
}
