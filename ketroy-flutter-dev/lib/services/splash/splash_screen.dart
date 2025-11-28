import 'package:flutter/material.dart';

class KetroyStyleSplashScreen extends StatefulWidget {
  const KetroyStyleSplashScreen({super.key});

  @override
  State<KetroyStyleSplashScreen> createState() =>
      _KetroyStyleSplashScreenState();
}

class _KetroyStyleSplashScreenState extends State<KetroyStyleSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Progress animation controller (больше не используется, но оставляем для совместимости)
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Pulse animation controller (больше не используется, но оставляем для совместимости)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  void _startAnimations() async {
    // Start logo animation
    await _logoController.forward();

    // Start pulse animation (repeats)
    _pulseController.repeat(reverse: true);

    // Start progress animation
    await _progressController.forward();

    // Navigate to next screen after animations complete
    if (mounted) {
      // Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Белый фон по умолчанию
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
            color: Colors.white, // Белый фон как fallback
            image: DecorationImage(
                image: AssetImage('images/back_image.jpg'), fit: BoxFit.cover)),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              SizedBox(
                  width: 207,
                  child: Image.asset('images/ketroy-splash-logo.png')),
              const Spacer(flex: 1),

              const Spacer(flex: 1),

              // Bottom padding
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
