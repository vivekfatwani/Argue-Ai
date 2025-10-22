import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/debate/text_debate_screen.dart';
import '../features/debate/voice_debate_screen.dart';
import '../features/feedback/feedback_screen.dart';
import '../features/roadmap/roadmap_screen.dart';
import '../features/history/history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../core/constants.dart';
import '../core/providers/user_provider.dart';
import '../core/utils/page_transitions.dart';
import 'dart:developer' as developer;

class AppRouter {
  // Error page builder
  static Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Something went wrong!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Error: ${state.error?.toString()}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.routeOnboarding),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }

  // Static method to create router
  static GoRouter router(UserProvider userProvider) {
    return GoRouter(
      initialLocation: AppConstants.routeSplash,
      refreshListenable: userProvider,
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final isLoggedIn = userProvider.isLoggedIn;
        final isLoading = userProvider.isLoading;
        final currentPath = state.matchedLocation;
        final isOnSplashPage = currentPath == AppConstants.routeSplash;
        final isOnLoginPage = currentPath == AppConstants.routeLogin;
        final isOnSignupPage = currentPath == AppConstants.routeSignup;
        final isOnOnboardingPage = currentPath == AppConstants.routeOnboarding;
        final isOnAuthPage = isOnLoginPage || isOnSignupPage || isOnOnboardingPage;
        
        // Log the current navigation state for debugging
        developer.log(
          'Router redirect: path=$currentPath, isLoggedIn=$isLoggedIn, isLoading=$isLoading',
          name: 'AppRouter',
        );
        
        // Don't redirect while loading
        if (isLoading) {
          developer.log('Still loading, staying on current page', name: 'AppRouter');
          return null;
        }
        
        // Handle splash screen - let it decide where to go
        if (isOnSplashPage) {
          developer.log('On splash page, letting splash screen handle navigation', name: 'AppRouter');
          return null;
        }
        
        // If logged in and trying to access auth pages, redirect to dashboard
        if (isLoggedIn && isOnAuthPage) {
          developer.log('Logged in user on auth page, redirecting to dashboard', name: 'AppRouter');
          return AppConstants.routeDashboard;
        }
        
        // If not logged in and trying to access protected pages, redirect to onboarding
        if (!isLoggedIn && !isOnAuthPage) {
          developer.log('Not logged in, trying to access protected page, redirecting to onboarding', name: 'AppRouter');
          return AppConstants.routeOnboarding;
        }
        
        developer.log('No redirect needed', name: 'AppRouter');
        return null;
      },
      routes: [
        GoRoute(
          path: AppConstants.routeSplash,
          pageBuilder: (context, state) => NoTransitionPage<void>(
            key: state.pageKey,
            child: const SplashScreen(),
          ),
        ),
        GoRoute(
          path: AppConstants.routeOnboarding,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const OnboardingScreen(),
            transitionsBuilder: AppPageTransitions.fadeTransition,
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        GoRoute(
          path: AppConstants.routeLogin,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: AppPageTransitions.fadeTransition,
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        GoRoute(
          path: AppConstants.routeSignup,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SignupScreen(),
            transitionsBuilder: AppPageTransitions.fadeTransition,
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        GoRoute(
          path: AppConstants.routeDashboard,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const DashboardScreen(),
            transitionsBuilder: AppPageTransitions.sharedAxisTransition,
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: AppConstants.routeTextDebate,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: TextDebateScreen(topic: state.extra as String? ?? ''),
            transitionsBuilder: AppPageTransitions.scaleTransition,
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        GoRoute(
          path: AppConstants.routeVoiceDebate,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: VoiceDebateScreen(topic: state.extra as String? ?? ''),
            transitionsBuilder: AppPageTransitions.scaleTransition,
            transitionDuration: const Duration(milliseconds: 350),
          ),
        ),
        GoRoute(
          path: AppConstants.routeFeedback,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: FeedbackScreen(debateId: state.extra as String? ?? ''),
            transitionsBuilder: AppPageTransitions.sharedAxisTransition,
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: AppConstants.routeRoadmap,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const RoadmapScreen(),
            transitionsBuilder: AppPageTransitions.sharedAxisTransition,
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: AppConstants.routeHistory,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const HistoryScreen(),
            transitionsBuilder: AppPageTransitions.sharedAxisTransition,
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
        GoRoute(
          path: AppConstants.routeProfile,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const ProfileScreen(),
            transitionsBuilder: AppPageTransitions.sharedAxisTransition,
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
      ],
      errorBuilder: (context, state) => _buildErrorPage(context, state),
    );
  }
}
