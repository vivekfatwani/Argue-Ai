import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:argumentor/routes/app_router.dart';
import 'package:argumentor/core/services/storage_service.dart';
import 'package:argumentor/core/services/ai_service.dart';
import 'package:argumentor/core/services/audio_service.dart';
import 'package:argumentor/core/providers/user_provider.dart';
import 'package:argumentor/core/providers/debate_provider.dart';
import 'package:argumentor/core/providers/feedback_provider.dart';
import 'package:argumentor/core/providers/theme_provider.dart';
import 'package:argumentor/core/providers/audio_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize services
  final storageService = StorageService();
  await storageService.init();
  
  // Initialize AI service with your API key
  const apiKey = 'AIzaSyC2BIc0pU7zxUCplaA1q6LYwJwtrV2AlYE'; // Gemini API key
  final aiService = AIService(apiKey);
  
  // Initialize audio service
  final audioService = AudioService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider(storageService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => DebateProvider(storageService, aiService)),
        ChangeNotifierProvider(create: (_) => FeedbackProvider(storageService, aiService)),
        ChangeNotifierProvider(create: (_) => AudioProvider(audioService, storageService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    
    return MaterialApp.router(
      title: 'ArguMentor',
      theme: themeProvider.currentTheme,
      routerConfig: AppRouter.router(userProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
