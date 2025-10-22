import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:argumentor/routes/app_router.dart';
import 'package:argumentor/core/services/storage_service.dart';
import 'package:argumentor/core/services/ai_service.dart';
import 'package:argumentor/core/services/audio_service.dart';
import 'package:argumentor/core/providers/user_provider.dart';
import 'package:argumentor/core/providers/debate_provider.dart';
import 'package:argumentor/core/providers/feedback_provider.dart';
import 'package:argumentor/core/providers/theme_provider.dart';
import 'package:argumentor/core/providers/audio_provider.dart';
import 'package:argumentor/core/config/api_keys.dart';
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
  final aiService = AIService(ApiKeys.geminiApiKey);
  
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _router = AppRouter.router(userProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp.router(
      title: 'ArgueAI',
      theme: themeProvider.currentTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
