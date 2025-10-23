import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants.dart';
import '../../widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to ArgueAI',
      description: 'Your AI-powered debate coach to help you master the art of persuasion',
      image: 'assets/images/onboarding_1.png',
    ),
    OnboardingPage(
      title: 'Real-time Debates',
      description: 'Practice debates with our AI in text or voice mode and receive instant feedback',
      image: 'assets/images/onboarding_2.png',
    ),
    OnboardingPage(
      title: 'Personalized Feedback',
      description: 'Get detailed analysis on your clarity, logic, rebuttals, and persuasiveness',
      image: 'assets/images/onboarding_3.png',
    ),
    OnboardingPage(
      title: 'Skill Development',
      description: 'Follow your personalized roadmap with curated resources to improve your skills',
      image: 'assets/images/onboarding_4.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppConstants.routeLogin),
                    child: const Text('Skip'),
                  ),
                  PageIndicator(
                    count: _pages.length,
                    currentIndex: _currentPage,
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage < _pages.length - 1 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: _buildOnboardingImage(page),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildOnboardingImage(OnboardingPage page) {
    // Extract the base name without extension
    final String basePath = page.image.substring(0, page.image.lastIndexOf('.'));
    final String svgPath = '$basePath.svg';
    
    return Stack(
      children: [
        // Base placeholder for immediate display
        _buildImagePlaceholder(),
        
        // Try to load the original PNG image
        Positioned.fill(
          child: Image.asset(
            page.image,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // On error, try to load the SVG version
              return SvgPicture.asset(
                svgPath,
                fit: BoxFit.contain,
                placeholderBuilder: (BuildContext context) => const SizedBox.shrink(),
                errorBuilder: (context, error, stackTrace) {
                  // Both PNG and SVG failed, placeholder is already showing behind
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logo_dev,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'ArguMentor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Your AI Debate Coach',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });
}
