import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoader extends StatelessWidget {
  const LottieLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/loading.json',
      width: 200,
      height: 200,
      fit: BoxFit.contain,
    );
  }
}
