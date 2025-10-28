# 🔍 ArguMentor - Developer Quick Reference

This is a quick reference guide for developers working on the ArguMentor project. For comprehensive details, see [COMPREHENSIVE_DOCUMENTATION.md](COMPREHENSIVE_DOCUMENTATION.md).

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/              # API keys and configuration
│   ├── constants.dart       # App-wide constants
│   ├── theme.dart           # Theme definitions
│   ├── models/              # Data models
│   │   ├── user_model.dart
│   │   ├── debate_model.dart
│   │   └── feedback_model.dart
│   ├── providers/           # State management
│   │   ├── user_provider.dart
│   │   ├── debate_provider.dart
│   │   ├── feedback_provider.dart
│   │   ├── theme_provider.dart
│   │   └── audio_provider.dart
│   ├── services/            # Business logic
│   │   ├── ai_service.dart
│   │   ├── storage_service.dart
│   │   └── audio_service.dart
│   └── utils/               # Helper functions
├── features/                # Feature modules
│   ├── auth/               # Authentication screens
│   ├── dashboard/          # Main dashboard
│   ├── debate/             # Debate screens
│   ├── feedback/           # Feedback display
│   ├── history/            # Debate history
│   ├── profile/            # User profile
│   ├── roadmap/            # Learning roadmap
│   ├── onboarding/         # First-time user flow
│   └── splash/             # Splash screen
├── widgets/                # Reusable widgets
├── routes/                 # Navigation
└── main.dart               # Entry point
```

---

## 🔑 Key Files & Their Purpose

| File | Purpose |
|------|---------|
| `main.dart` | App initialization, provider setup, Firebase init |
| `app_router.dart` | Navigation configuration with route guards |
| `user_provider.dart` | User authentication and profile management |
| `debate_provider.dart` | Debate session management and AI responses |
| `ai_service.dart` | All Gemini API interactions |
| `storage_service.dart` | Local and cloud data persistence |
| `user_model.dart` | User data structure |
| `debate_model.dart` | Debate session data structure |

---

## 🎨 Core Providers & Their Responsibilities

### UserProvider
```dart
// Manages: User authentication, profile data, Firebase sync
Future<void> login(String email, String password)
Future<void> signup(String name, String email, String password)
Future<void> logout()
Future<void> updateUser(User user)
User? get currentUser
bool get isLoggedIn
```

### DebateProvider
```dart
// Manages: Active debate session, messages, AI responses
Future<void> startDebate(String topic, DebateMode mode)
Future<void> addUserMessage(String content)
Future<void> generateAiResponse()
Future<void> endDebate()
Future<Map<String, dynamic>> generateFeedback()
Debate? get currentDebate
bool get isAiTyping
```

### FeedbackProvider
```dart
// Manages: Feedback data, learning recommendations
Future<void> loadFeedback(String debateId)
Future<List<Map<String, dynamic>>> getRecommendations()
Map<String, double>? get skillRatings
```

### ThemeProvider
```dart
// Manages: App theme (light/dark mode)
void toggleTheme()
ThemeData get currentTheme
bool get isDarkMode
```

### AudioProvider
```dart
// Manages: Voice recording, playback, speech-to-text
Future<void> startRecording()
Future<String> stopRecording()
Future<void> playAudio(String path)
bool get isRecording
```

---

## 🤖 AI Service Methods

### 1. Generate Debate Response
```dart
Future<String> generateDebateResponse(
  String topic, 
  List<DebateMessage> history
)
```
**Purpose:** Generate AI's next argument in the debate  
**Input:** Topic and conversation history  
**Output:** AI's response (3-5 sentences)  
**Model Config:** Temperature 0.7, Top K 40, Top P 0.95

### 2. Generate Feedback
```dart
Future<Map<String, dynamic>> generateDebateFeedback(
  String topic, 
  List<DebateMessage> messages
)
```
**Purpose:** Analyze debate performance  
**Input:** Topic and full transcript  
**Output:** JSON with skillRatings, strengths, improvements, overallFeedback

### 3. Generate Recommendations
```dart
Future<List<Map<String, dynamic>>> generateLearningRecommendations(
  Map<String, double> skillRatings
)
```
**Purpose:** Suggest learning resources  
**Input:** User's skill ratings  
**Output:** List of recommended resources

---

## 💾 Data Models

### User Model
```dart
class User {
  String id;              // Firebase Auth UID
  String name;
  String email;
  DateTime createdAt;
  DateTime lastActive;
  int points;             // Gamification points
  Map<String, double> skills;  // clarity, logic, rebuttalQuality, persuasiveness
  List<String> completedResources;
  UserPreferences preferences;
}
```

### Debate Model
```dart
class Debate {
  String id;              // Unique debate ID
  String topic;
  DebateMode mode;        // text or voice
  List<DebateMessage> messages;
  DateTime startTime;
  DateTime? endTime;
  Map<String, double>? feedback;  // Skill ratings from AI
}
```

### DebateMessage Model
```dart
class DebateMessage {
  String content;
  bool isUser;            // true = user, false = AI
  DateTime timestamp;
}
```

---

## 🔥 Firebase Structure

```
Firestore Database:
└── users (collection)
    └── {userId} (document)
        ├── name: string
        ├── email: string
        ├── createdAt: timestamp
        ├── points: number
        ├── skills: map
        ├── completedResources: array
        ├── preferences: map
        │
        ├── debates (subcollection)
        │   └── {debateId} (document)
        │       ├── topic: string
        │       ├── mode: string
        │       ├── messages: array
        │       ├── startTime: timestamp
        │       ├── endTime: timestamp
        │       └── feedback: map
        │
        └── resources (subcollection)
            └── {resourceId} (document)
                ├── title: string
                ├── completedAt: timestamp
                └── notes: string
```

---

## 🛣️ Navigation Routes

```dart
Routes defined in app_router.dart:

/splash              → Splash Screen (auto-redirect)
/onboarding          → Onboarding screens
/auth/login          → Login screen
/auth/signup         → Signup screen
/dashboard           → Main dashboard (requires auth)
/debate/select       → Topic selector
/debate/text         → Text debate screen
/debate/voice        → Voice debate screen
/feedback            → Feedback screen
/history             → Debate history
/roadmap             → Learning roadmap
/profile             → User profile
```

**Route Guards:**
- Unauthenticated users → redirected to `/auth/login`
- Authenticated users on auth routes → redirected to `/dashboard`

---

## 🔐 Environment Variables

### API Keys (lib/core/config/api_keys.dart)
```dart
class ApiKeys {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  // Add other API keys as needed
}
```

**⚠️ IMPORTANT:** This file is in `.gitignore` - never commit actual API keys!

### Template File
A template file exists at `lib/core/config/api_keys.dart.template` for team members.

---

## 📝 Common Tasks

### Adding a New Screen
1. Create file in `lib/features/{feature_name}/`
2. Add route in `lib/routes/app_router.dart`
3. Import and use in navigation

### Adding a New Provider
1. Create file in `lib/core/providers/`
2. Extend `ChangeNotifier`
3. Add to `MultiProvider` in `main.dart`
4. Use with `Provider.of<T>(context)` or `Consumer<T>`

### Adding a New Model
1. Create file in `lib/core/models/`
2. Implement `toJson()` and `fromJson()` methods
3. Use in providers and services

### Making API Calls
```dart
// AI Service call
final response = await Provider.of<DebateProvider>(context, listen: false)
    .aiService
    .generateDebateResponse(topic, history);

// Firestore call
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update(data);
```

---

## 🧪 Testing Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/user_model_test.dart

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

---

## 🚀 Build Commands

```bash
# Run app in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# Build Android APK
flutter build apk

# Build Android App Bundle
flutter build appbundle

# Build iOS
flutter build ios

# Clean build
flutter clean && flutter pub get
```

---

## 🐛 Common Issues & Solutions

### Issue: Firebase not initialized
```bash
Solution: Check that Firebase.initializeApp() is called in main.dart before runApp()
```

### Issue: Provider not found
```bash
Solution: Ensure provider is added to MultiProvider in main.dart
```

### Issue: API key error
```bash
Solution: Check that lib/core/config/api_keys.dart exists and contains valid keys
```

### Issue: Build fails
```bash
Solution: Run `flutter clean && flutter pub get && flutter run`
```

### Issue: Hot reload not working
```bash
Solution: Use hot restart (Ctrl+Shift+F5) or full restart
```

---

## 📊 Performance Best Practices

1. **State Management:**
   - Only call `notifyListeners()` when state actually changes
   - Use `Consumer` for granular rebuilds
   - Avoid rebuilding entire widget tree

2. **API Calls:**
   - Cache responses when possible
   - Use debounce for user input
   - Cancel pending requests on screen exit

3. **UI Optimization:**
   - Use `const` constructors
   - Implement `ListView.builder` for long lists
   - Optimize image loading

4. **Memory Management:**
   - Dispose controllers in `dispose()`
   - Close streams and subscriptions
   - Release audio resources

---

## 🔒 Security Checklist

- [ ] API keys in `.gitignore`
- [ ] Firebase security rules configured
- [ ] Client-side input validation
- [ ] HTTPS for all API calls
- [ ] No sensitive data in logs
- [ ] User data encrypted in transit
- [ ] Proper authentication checks

---

## 📚 Useful Resources

### Flutter
- [Flutter Docs](https://flutter.dev/docs)
- [Dart Docs](https://dart.dev/guides)
- [Flutter Packages](https://pub.dev)

### Firebase
- [Firebase Docs](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev/)

### AI Integration
- [Gemini API Docs](https://ai.google.dev/docs)
- [Google Generative AI Package](https://pub.dev/packages/google_generative_ai)

### State Management
- [Provider Package](https://pub.dev/packages/provider)
- [Provider Documentation](https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple)

---

## 🎯 Quick Reference Commands

```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Check outdated packages
flutter pub outdated

# Run app
flutter run

# Hot reload
Press 'r' in terminal

# Hot restart
Press 'R' in terminal

# Build for release
flutter build apk --release

# List devices
flutter devices

# Clear cache
flutter clean

# Doctor check
flutter doctor
```

---

## 🔗 Related Documentation

- [COMPREHENSIVE_DOCUMENTATION.md](COMPREHENSIVE_DOCUMENTATION.md) - Complete technical guide
- [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) - Architecture diagrams and flows
- [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md) - Firebase configuration
- [QUICK_START.md](QUICK_START.md) - 5-minute setup guide

---

## 💡 Development Tips

1. **Use Flutter DevTools** for debugging and performance profiling
2. **Enable null safety** - project uses sound null safety
3. **Follow Flutter style guide** - use `flutter format`
4. **Test on multiple devices** - different screen sizes and OS versions
5. **Use meaningful commit messages** - helps with tracking changes
6. **Document complex logic** - add comments for future maintainers
7. **Keep packages updated** - regularly check for security updates

---

## 🆘 Getting Help

- Check [COMPREHENSIVE_DOCUMENTATION.md](COMPREHENSIVE_DOCUMENTATION.md) for detailed explanations
- Review [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) for architecture questions
- Look at existing code for patterns and examples
- Search [Flutter documentation](https://flutter.dev/docs)
- Check [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

**Happy Coding! 🚀**
