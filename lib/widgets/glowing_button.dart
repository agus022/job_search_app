import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GlowingButton extends StatefulWidget {
  final dynamic user;
  const GlowingButton({Key? key, required this.user}) : super(key: key);

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 5.0, end: 10.0),
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      const Color.fromARGB(255, 245, 241, 11).withOpacity(0.8),
                  blurRadius: value,
                  spreadRadius: value / 3,
                ),
              ],
            ),
            child: child,
          );
        },
        onEnd: () {
          // Reversa la animación al finalizar
          setState(() {});
        },
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/job_detail',
              arguments: widget.user,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFFD55),
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            elevation: 0,
          ),
          child: SvgPicture.asset(
            'assets/svg/arrow-top-right.svg',
            width: 24,
            height: 24,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
