import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_search_oficial/core/services/shared_prefs_service.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/img/onboard1.png",
      "title": "Bienvenido",
      "description": "Tu app ideal para todo lo que necesitas.",
    },
    {
      "image": "assets/img/onboard2.png",
      "title": "Organiza fácilmente",
      "description": "Administra todo con solo unos toques.",
    },
    {
      "image": "assets/img/onboard3.png",
      "title": "Comienza ahora",
      "description": "Únete y empieza a disfrutar.",
    },
  ];

  void _goToLogin() async {
    await SharedPrefsService.setFirstLaunch(false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(page["image"]!, height: 350)
                        .animate()
                        .fadeIn()
                        .scale(),
                    const SizedBox(height: 20),
                    Text(
                      page["title"]!,
                      style: GoogleFonts.dmSans(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        page["description"]!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Color.fromARGB(255, 131, 131, 131),
                        ),
                      ).animate().fadeIn(delay: 500.ms),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              return Container(
                margin: const EdgeInsets.all(4),
                width: _currentPage == index ? 25 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _currentPage == index ? Color(0xFF07689F) : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: _currentPage == _pages.length - 1
                ? _goToLogin
                : () {
                    _controller.nextPage(
                        duration: 500.ms, curve: Curves.easeInOut);
                  },
            child: Text(
                _currentPage == _pages.length - 1 ? "Comenzar" : "Siguiente"),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
