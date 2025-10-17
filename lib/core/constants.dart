class AppConstants {
  // App Information
  static const String appName = 'ArguMentor';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered Debate Coach';
  
  // Routes
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeDashboard = '/dashboard';
  static const String routeTextDebate = '/debate/text';
  static const String routeVoiceDebate = '/debate/voice';
  static const String routeFeedback = '/feedback';
  static const String routeRoadmap = '/roadmap';
  static const String routeHistory = '/history';
  static const String routeProfile = '/profile';
  
  // Debate Topics
  static const List<String> debateTopics = [
    'Should social media be regulated by governments?',
    'Is artificial intelligence beneficial for humanity?',
    'Should college education be free?',
    'Is climate change primarily caused by human activities?',
    'Should voting be mandatory?',
    'Should autonomous weapons be banned?',
    'Is universal basic income a good idea?',
    'Should genetic engineering of humans be allowed?',
    'Is nuclear energy safe and sustainable?',
    'Should there be limits on free speech?',
  ];
  
  // Skill Categories
  static const List<String> skillCategories = [
    'Clarity',
    'Logic',
    'Rebuttal Quality',
    'Persuasiveness',
  ];
  
  // Storage Keys
  static const String keyUserProfile = 'user_profile';
  static const String keyDebateHistory = 'debate_history';
  static const String keyUserPreferences = 'user_preferences';
  static const String keyUserSkills = 'user_skills';
  
  // API Settings
  static const String geminiApiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const int maxTokensPerRequest = 1024;
  static const int maxResponseTokens = 2048;
  
  // Animations
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  static const String microphoneAnimation = 'assets/animations/microphone.json';
  static const String typingAnimation = 'assets/animations/typing.json';
  
  // Timeouts
  static const int debateResponseTimeoutSeconds = 30;
  static const int voiceRecognitionTimeoutSeconds = 10;
  
  // Gamification
  static const int pointsPerDebate = 10;
  static const int pointsPerSkillImprovement = 5;
  static const int pointsPerResourceCompleted = 3;
  
  // Badge Levels
  static const int bronzeBadgeThreshold = 50;
  static const int silverBadgeThreshold = 100;
  static const int goldBadgeThreshold = 200;
  static const int platinumBadgeThreshold = 500;
}
