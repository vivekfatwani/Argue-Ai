import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants.dart';
import '../../core/providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    
    // Pulse effect controller (continuous)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Fade in animation
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    // Scale animation with bounce effect
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );
    
    // Subtle pulse animation (continuous)
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Slide up animation for text
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    
    // Subtle rotation animation
    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    // Start animations
    _mainController.forward();
    _pulseController.repeat(reverse: true);
    
    // Navigate to the appropriate screen after animation completes
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkUserAndNavigate();
      }
    });
  }
  
  Future<void> _checkUserAndNavigate() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Wait a bit to show the splash screen
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      if (userProvider.isLoggedIn) {
        context.go(AppConstants.routeDashboard);
      } else {
        context.go(AppConstants.routeOnboarding);
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF303F9F), const Color(0xFF1A237E)],
            stops: const [0.3, 0.9],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_mainController, _pulseController]),
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeInAnimation,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with scale and pulse animations
                      Transform.scale(
                        scale: _scaleAnimation.value * _pulseAnimation.value,
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Image.asset('assets/images/argumentor_logo.png'),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // App Name with slide animation
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: const Text(
                          'ArgueAI',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x88000000),
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tagline with slide animation (delayed)
                      Transform.translate(
                        offset: Offset(0, _slideAnimation.value * 1.5),
                        child: const Text(
                          'AI-Powered Debate Coach',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
