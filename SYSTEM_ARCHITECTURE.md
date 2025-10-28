# 🏗️ ArguMentor - System Architecture & Flow Diagrams

This document provides visual representations of the ArguMentor system architecture, data flows, and component interactions.

---

## 📐 High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          ARGUEMENTOR APP                             │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                    PRESENTATION LAYER                       │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │    │
│  │  │Dashboard │  │  Debate  │  │ Feedback │  │ Profile  │  │    │
│  │  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │  │    │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │    │
│  │                                                             │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │    │
│  │  │  Login   │  │  Signup  │  │ History  │  │ Roadmap  │  │    │
│  │  │  Screen  │  │  Screen  │  │  Screen  │  │  Screen  │  │    │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │    │
│  └────────────────────────────────────────────────────────────┘    │
│                              ▲                                       │
│                              │ notifyListeners()                    │
│                              │                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │              STATE MANAGEMENT LAYER (Provider)              │    │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │    │
│  │  │    User     │  │   Debate     │  │   Feedback      │  │    │
│  │  │  Provider   │  │   Provider   │  │   Provider      │  │    │
│  │  └─────────────┘  └──────────────┘  └─────────────────┘  │    │
│  │  ┌─────────────┐  ┌──────────────┐                        │    │
│  │  │   Theme     │  │    Audio     │                        │    │
│  │  │  Provider   │  │   Provider   │                        │    │
│  │  └─────────────┘  └──────────────┘                        │    │
│  └────────────────────────────────────────────────────────────┘    │
│                              ▲                                       │
│                              │ calls methods                        │
│                              │                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                   BUSINESS LOGIC LAYER                      │    │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐  │    │
│  │  │    User     │  │   Debate     │  │   Feedback      │  │    │
│  │  │   Model     │  │   Model      │  │    Model        │  │    │
│  │  └─────────────┘  └──────────────┘  └─────────────────┘  │    │
│  │                                                             │    │
│  │  ┌────────────────────────────────────────────────────┐   │    │
│  │  │           Utilities & Helper Functions             │   │    │
│  │  └────────────────────────────────────────────────────┘   │    │
│  └────────────────────────────────────────────────────────────┘    │
│                              ▲                                       │
│                              │ uses                                 │
│                              │                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                     SERVICES LAYER                          │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │    │
│  │  │  AI Service  │  │   Storage    │  │    Audio     │    │    │
│  │  │  (Gemini)    │  │   Service    │  │   Service    │    │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │    │
│  └────────────────────────────────────────────────────────────┘    │
│                              ▲                                       │
│                              │ communicates with                    │
│                              │                                       │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
    ┌───────────────────────┐     ┌──────────────────────┐
    │   EXTERNAL SERVICES   │     │   LOCAL STORAGE      │
    │                       │     │                      │
    │  ┌────────────────┐  │     │  ┌───────────────┐  │
    │  │ Google Gemini  │  │     │  │  Shared       │  │
    │  │  API (2.5)     │  │     │  │  Preferences  │  │
    │  └────────────────┘  │     │  └───────────────┘  │
    │                       │     │                      │
    │  ┌────────────────┐  │     │  ┌───────────────┐  │
    │  │   Firebase     │  │     │  │  Local Files  │  │
    │  │   Auth         │  │     │  │  (Cache)      │  │
    │  └────────────────┘  │     │  └───────────────┘  │
    │                       │     │                      │
    │  ┌────────────────┐  │     └──────────────────────┘
    │  │  Firestore     │  │
    │  │  Database      │  │
    │  └────────────────┘  │
    │                       │
    │  ┌────────────────┐  │
    │  │  Firebase      │  │
    │  │  Storage       │  │
    │  └────────────────┘  │
    └───────────────────────┘
```

---

## 🔄 Data Flow Diagrams

### 1. User Authentication Flow

```
┌─────────────────┐
│   User Opens    │
│      App        │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│   Splash Screen                     │
│   - Initialize Firebase             │
│   - Check Auth State                │
└────────┬────────────────────────────┘
         │
         ├─────────────────┐
         │                 │
    Auth Found        No Auth
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌──────────────┐
│ Load User Data  │  │ Onboarding   │
│ from Firestore  │  │   Screen     │
└────────┬────────┘  └──────┬───────┘
         │                   │
         │                   ▼
         │            ┌──────────────┐
         │            │Login/Signup  │
         │            │   Screen     │
         │            └──────┬───────┘
         │                   │
         │            User Enters Credentials
         │                   │
         │                   ▼
         │            ┌─────────────────────┐
         │            │ UserProvider.login()│
         │            │ or .signup()        │
         │            └──────┬──────────────┘
         │                   │
         │            ┌──────┴──────┐
         │            │             │
         │         Success       Error
         │            │             │
         │            ▼             ▼
         │     ┌────────────┐  ┌─────────┐
         │     │Create User │  │  Show   │
         │     │in Firebase │  │  Error  │
         │     │& Firestore │  └─────────┘
         │     └──────┬─────┘
         │            │
         └────────────┘
                 │
                 ▼
         ┌───────────────┐
         │   Dashboard   │
         │  (Logged In)  │
         └───────────────┘
```

### 2. Debate Session Flow

```
┌──────────────────┐
│   Dashboard      │
│ User clicks      │
│"Start Debate"    │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│ Topic Selector Screen    │
│ User selects:            │
│ - Topic                  │
│ - Mode (Text/Voice)      │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ DebateProvider.startDebate()         │
│ - Create new Debate instance         │
│ - Generate ID, set start time        │
│ - Add initial AI greeting            │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ Debate Screen                        │
│ (Text or Voice mode)                 │
└────────┬─────────────────────────────┘
         │
         ├──────────────────────┐
         │                      │
    ┌────▼────┐           ┌─────▼─────┐
    │  USER   │           │    AI     │
    │  TURN   │           │   TURN    │
    └────┬────┘           └─────▲─────┘
         │                      │
         │ Types/Speaks         │
         │ Message              │
         │                      │
         ▼                      │
┌─────────────────────────┐    │
│addUserMessage()         │    │
│- Create message object  │    │
│- Add to debate messages │    │
│- Save to storage        │    │
│- Trigger AI response    │    │
└────────┬────────────────┘    │
         │                     │
         ▼                     │
┌──────────────────────────┐  │
│generateAiResponse()      │  │
│- Set isAiTyping=true     │  │
│- Show typing indicator   │  │
└────────┬─────────────────┘  │
         │                     │
         ▼                     │
┌─────────────────────────────┤
│ AIService.generate          │
│ DebateResponse()            │
│- Format history             │
│- Create prompt              │
│- Call Gemini API            │
│- Parse response             │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────┐
│addAiMessage()           │
│- Create AI message      │
│- Add to debate          │
│- Save to storage        │
│- Set isAiTyping=false   │
└────────┬────────────────┘
         │
         ▼
     Continue Debate
     (Loop back to user turn)
         │
         │ User clicks
         │ "End Debate"
         │
         ▼
┌─────────────────────────┐
│endDebate()              │
│- Set end time           │
│- Save final state       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│Navigate to Feedback     │
└─────────────────────────┘
```

### 3. AI Feedback Generation Flow

```
┌─────────────────┐
│ Debate Ends     │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────┐
│ Feedback Screen              │
│ - Show loading state         │
└────────┬─────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ DebateProvider.generateFeedback()    │
│ - Check debate is completed          │
│ - Set loading state                  │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ AIService.generateDebateFeedback()   │
└────────┬─────────────────────────────┘
         │
         ├──── Step 1: Format Transcript
         │
         ▼
┌──────────────────────────────────────┐
│ Create Debate Transcript             │
│ User: [message 1]                    │
│ AI: [message 2]                      │
│ User: [message 3]                    │
│ ...                                  │
└────────┬─────────────────────────────┘
         │
         ├──── Step 2: Create Prompt
         │
         ▼
┌──────────────────────────────────────┐
│ Prompt to Gemini:                    │
│ "Analyze this debate on {topic}     │
│  Provide feedback in JSON format:   │
│  {                                   │
│    skillRatings: {...},              │
│    strengths: [...],                 │
│    improvements: [...],              │
│    overallFeedback: "..."           │
│  }"                                  │
└────────┬─────────────────────────────┘
         │
         ├──── Step 3: Send to Gemini API
         │
         ▼
┌──────────────────────────────────────┐
│ Gemini API Processing                │
│ - Analyzes conversation              │
│ - Evaluates skills:                  │
│   • Clarity (0.0-1.0)                │
│   • Logic (0.0-1.0)                  │
│   • Rebuttal Quality (0.0-1.0)       │
│   • Persuasiveness (0.0-1.0)         │
│ - Identifies strengths               │
│ - Suggests improvements              │
│ - Writes overall feedback            │
└────────┬─────────────────────────────┘
         │
         ├──── Step 4: Parse Response
         │
         ▼
┌──────────────────────────────────────┐
│ Parse JSON Response                  │
│ - Extract skillRatings object        │
│ - Extract strengths array            │
│ - Extract improvements array         │
│ - Extract overallFeedback string     │
│ - Handle parsing errors              │
└────────┬─────────────────────────────┘
         │
         ├──── Step 5: Save Feedback
         │
         ▼
┌──────────────────────────────────────┐
│ Update Debate Record                 │
│ - Add feedback to debate             │
│ - Save to local storage              │
│ - Save to Firestore                  │
└────────┬─────────────────────────────┘
         │
         ├──── Step 6: Update User Stats
         │
         ▼
┌──────────────────────────────────────┐
│ Update User's Skill Statistics       │
│ - Average new ratings with existing  │
│ - Update skill levels                │
│ - Award points                       │
│ - Check for achievements             │
└────────┬─────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ Display Feedback                     │
│ ┌────────────────────────────────┐  │
│ │ Skill Ratings (Progress Bars)  │  │
│ ├────────────────────────────────┤  │
│ │ Strengths (Checkmark List)     │  │
│ ├────────────────────────────────┤  │
│ │ Improvements (Lightbulb List)  │  │
│ ├────────────────────────────────┤  │
│ │ Overall Feedback (Text Card)   │  │
│ └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### 4. Learning Roadmap Flow

```
┌─────────────────────┐
│ User Views Roadmap  │
└──────────┬──────────┘
           │
           ▼
┌───────────────────────────────────┐
│ RoadmapScreen                     │
│ - Display skill tabs              │
│   • Clarity                       │
│   • Logic                         │
│   • Rebuttal Quality              │
│   • Persuasiveness                │
└──────────┬────────────────────────┘
           │
           │ User selects a skill
           │
           ▼
┌───────────────────────────────────┐
│ Load Resources for Selected Skill │
└──────────┬────────────────────────┘
           │
           ├──── From User's Skill Rating
           │
           ▼
┌────────────────────────────────────────┐
│ AIService.generateLearning             │
│ Recommendations()                      │
│                                        │
│ Input: { clarity: 0.7, logic: 0.6 }  │
└──────────┬─────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────┐
│ Gemini Generates Recommendations       │
│ Based on weak skills:                  │
│                                        │
│ [                                      │
│   {                                    │
│     title: "Logical Fallacies",       │
│     type: "video",                     │
│     targetSkills: ["logic"],          │
│     url: "..."                         │
│   },                                   │
│   ...                                  │
│ ]                                      │
└──────────┬─────────────────────────────┘
           │
           ▼
┌───────────────────────────────────┐
│ Display Resource Cards            │
│ ┌─────────────────────────────┐  │
│ │ 📹 Video: "Logical Fallacies"│  │
│ │ Target: Logic                │  │
│ │ [ ] Mark as Complete         │  │
│ └─────────────────────────────┘  │
│ ┌─────────────────────────────┐  │
│ │ 📄 Article: "Clarity Tips"  │  │
│ │ Target: Clarity              │  │
│ │ [✓] Completed                │  │
│ └─────────────────────────────┘  │
└───────────────────────────────────┘
           │
           │ User clicks
           │ "Mark as Complete"
           │
           ▼
┌───────────────────────────────────┐
│ Update User Progress              │
│ - Add to completedResources       │
│ - Award points                    │
│ - Check for achievements          │
│ - Save to storage & Firestore     │
└───────────────────────────────────┘
```

---

## 🗂️ Data Models & Relationships

```
┌──────────────────────────────────────────────────────────────┐
│                          USER MODEL                           │
├──────────────────────────────────────────────────────────────┤
│ id: String (UUID)                                            │
│ name: String                                                 │
│ email: String                                                │
│ createdAt: DateTime                                          │
│ lastActive: DateTime                                         │
│ points: int                                                  │
│ skills: Map<String, double>                                  │
│   ├─ clarity: double (0.0-1.0)                              │
│   ├─ logic: double (0.0-1.0)                                │
│   ├─ rebuttalQuality: double (0.0-1.0)                      │
│   └─ persuasiveness: double (0.0-1.0)                       │
│ completedResources: List<String>                            │
│ preferences: UserPreferences                                 │
│   ├─ darkMode: bool                                         │
│   ├─ notificationsEnabled: bool                             │
│   ├─ voiceSpeed: double                                     │
│   └─ voicePitch: double                                     │
└──────────────────────────────────────────────────────────────┘
                          │ has many
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                        DEBATE MODEL                           │
├──────────────────────────────────────────────────────────────┤
│ id: String (UUID)                                            │
│ topic: String                                                │
│ mode: DebateMode (text/voice)                               │
│ messages: List<DebateMessage>                               │
│ startTime: DateTime                                          │
│ endTime: DateTime?                                           │
│ feedback: Map<String, double>?                              │
│   ├─ clarity: double                                        │
│   ├─ logic: double                                          │
│   ├─ rebuttalQuality: double                                │
│   └─ persuasiveness: double                                 │
└──────────────────────────────────────────────────────────────┘
                          │ contains many
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                    DEBATE MESSAGE MODEL                       │
├──────────────────────────────────────────────────────────────┤
│ content: String                                              │
│ isUser: bool (true=user, false=AI)                          │
│ timestamp: DateTime                                          │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                       FEEDBACK MODEL                          │
├──────────────────────────────────────────────────────────────┤
│ id: String                                                   │
│ debateId: String (references Debate)                        │
│ skillRatings: Map<String, double>                           │
│ strengths: List<String>                                      │
│ improvements: List<String>                                   │
│ overallFeedback: String                                      │
│ createdAt: DateTime                                          │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔌 Service Integration Diagram

```
┌────────────────────────────────────────────────────────────┐
│                      ARGUEMENTOR APP                        │
└────────────────────────┬───────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌───────────────┐  ┌──────────────┐  ┌─────────────┐
│  AI SERVICE   │  │   STORAGE    │  │   AUDIO     │
│   (Gemini)    │  │   SERVICE    │  │  SERVICE    │
└───────┬───────┘  └──────┬───────┘  └──────┬──────┘
        │                 │                  │
        │                 │                  │
        ▼                 ├──────────┬───────┼──────┐
┌────────────────┐        │          │       │      │
│ Google Gemini  │        ▼          ▼       ▼      ▼
│  API (2.5)     │  ┌─────────┐ ┌─────┐ ┌────┐ ┌──────┐
│                │  │Firebase │ │Local│ │File│ │Speech│
│ Configuration: │  │Firestore│ │ SP  │ │Sys │ │ API  │
│ • Temperature  │  └─────────┘ └─────┘ └────┘ └──────┘
│   0.7          │
│ • Top K: 40    │  SP = SharedPreferences
│ • Top P: 0.95  │  File Sys = File System
│ • Max Tokens:  │
│   2048         │
└────────────────┘

Gemini API Endpoints:
┌────────────────────────────────────────────────┐
│ 1. generateDebateResponse()                    │
│    - Input: topic, conversation history        │
│    - Output: AI's next argument                │
│                                                │
│ 2. generateDebateFeedback()                    │
│    - Input: topic, full transcript             │
│    - Output: Structured JSON feedback          │
│                                                │
│ 3. generateLearningRecommendations()           │
│    - Input: skill ratings                      │
│    - Output: Learning resource list            │
└────────────────────────────────────────────────┘

Firebase Services:
┌────────────────────────────────────────────────┐
│ 1. Firebase Auth                               │
│    - Email/Password authentication             │
│    - User session management                   │
│                                                │
│ 2. Cloud Firestore                             │
│    Collections:                                │
│    • users/{userId}                            │
│      ├─ debates/{debateId}                     │
│      └─ resources/{resourceId}                 │
│                                                │
│ 3. Firebase Storage (Optional)                 │
│    - Profile pictures                          │
│    - Debate audio recordings                   │
└────────────────────────────────────────────────┘
```

---

## 🔄 State Management Flow

```
┌────────────────────────────────────────────────────────────┐
│                    PROVIDER PATTERN                         │
└────────────────────────────────────────────────────────────┘

User Action (e.g., sends message in debate)
    │
    ▼
┌─────────────────────────────────────────────┐
│ UI Widget                                   │
│ TextDebateScreen                            │
│                                             │
│ onSendMessage() {                           │
│   debateProvider.addUserMessage(text);      │
│ }                                           │
└────────────────┬────────────────────────────┘
                 │ calls method
                 ▼
┌──────────────────────────────────────────────────────────┐
│ DebateProvider (extends ChangeNotifier)                  │
│                                                          │
│ Future<void> addUserMessage(String content) async {     │
│   // 1. Update internal state                           │
│   _currentDebate.messages.add(message);                 │
│                                                          │
│   // 2. Persist to storage                              │
│   await _storageService.saveDebate(_currentDebate);     │
│                                                          │
│   // 3. Notify listeners (triggers rebuild)             │
│   notifyListeners();  ◄──────────────────────┐          │
│                                               │          │
│   // 4. Generate AI response                 │          │
│   await generateAiResponse();                 │          │
│ }                                             │          │
└───────────────────────────────────────────────┼──────────┘
                                                │
                                                │ rebuild
                                                │
┌───────────────────────────────────────────────▼──────────┐
│ UI Widget (listening to provider)                        │
│                                                          │
│ Consumer<DebateProvider>(                               │
│   builder: (context, provider, child) {                 │
│     return ListView(                                    │
│       children: provider.currentDebate.messages         │
│         .map((msg) => DebateBubble(msg))               │
│         .toList(),                                      │
│     );                                                   │
│   }                                                      │
│ )                                                        │
└──────────────────────────────────────────────────────────┘

Provider Dependency Injection:
┌────────────────────────────────────────────────────────┐
│ main.dart                                              │
│                                                        │
│ MultiProvider(                                         │
│   providers: [                                         │
│     ChangeNotifierProvider(                            │
│       create: (_) => UserProvider(storageService)      │
│     ),                                                 │
│     ChangeNotifierProvider(                            │
│       create: (_) => DebateProvider(                   │
│         storageService,                                │
│         aiService                                      │
│       )                                                │
│     ),                                                 │
│     ChangeNotifierProvider(                            │
│       create: (_) => FeedbackProvider(...)             │
│     ),                                                 │
│     // ... more providers                              │
│   ],                                                   │
│   child: MyApp(),                                      │
│ )                                                      │
└────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Architecture

```
┌────────────────────────────────────────────────────────────┐
│                   SECURITY LAYERS                           │
└────────────────────────────────────────────────────────────┘

Layer 1: API Key Management
┌──────────────────────────────────────────────────────────┐
│ api_keys.dart (in .gitignore)                            │
│ ├─ Gemini API Key                                        │
│ └─ Other API Keys                                        │
│                                                          │
│ ✓ Not committed to version control                      │
│ ✓ Template file for team members                        │
│ ✓ Environment-specific keys                             │
└──────────────────────────────────────────────────────────┘

Layer 2: Firebase Security Rules
┌──────────────────────────────────────────────────────────┐
│ Firestore Rules:                                         │
│                                                          │
│ match /users/{userId} {                                  │
│   allow read, write: if request.auth.uid == userId;     │
│                                                          │
│   match /debates/{debateId} {                            │
│     allow read, write: if request.auth.uid == userId;   │
│   }                                                      │
│                                                          │
│   match /resources/{resourceId} {                        │
│     allow read, write: if request.auth.uid == userId;   │
│   }                                                      │
│ }                                                        │
│                                                          │
│ ✓ Users can only access their own data                  │
│ ✓ Authentication required for all operations            │
│ ✓ Subcollections inherit parent rules                   │
└──────────────────────────────────────────────────────────┘

Layer 3: Client-Side Validation
┌──────────────────────────────────────────────────────────┐
│ Input Validation:                                        │
│ ├─ Email format validation                              │
│ ├─ Password strength requirements                       │
│ ├─ Form field validation                                │
│ └─ Sanitize user input                                  │
│                                                          │
│ ✓ Validate before API calls                             │
│ ✓ Prevent injection attacks                             │
│ ✓ User-friendly error messages                          │
└──────────────────────────────────────────────────────────┘

Layer 4: Secure Communication
┌──────────────────────────────────────────────────────────┐
│ Network Security:                                        │
│ ├─ HTTPS for all API calls                              │
│ ├─ Firebase secure connections                          │
│ ├─ Certificate pinning (optional)                       │
│ └─ No sensitive data in logs                            │
│                                                          │
│ ✓ Encrypted data transmission                           │
│ ✓ Secure token management                               │
│ ✓ Session timeout handling                              │
└──────────────────────────────────────────────────────────┘

Layer 5: Data Privacy
┌──────────────────────────────────────────────────────────┐
│ Privacy Measures:                                        │
│ ├─ Minimal data collection                              │
│ ├─ User consent for data usage                          │
│ ├─ Account deletion capability                          │
│ └─ GDPR compliance                                       │
│                                                          │
│ ✓ Transparent data usage                                │
│ ✓ User control over data                                │
│ ✓ Secure data deletion                                  │
└──────────────────────────────────────────────────────────┘
```

---

## 📱 Screen Navigation Map

```
┌─────────────────────────────────────────────────────────────┐
│                    SCREEN NAVIGATION                         │
└─────────────────────────────────────────────────────────────┘

                     App Launch
                         │
                         ▼
                 ┌───────────────┐
                 │Splash Screen  │
                 │(Auto-redirect)│
                 └───────┬───────┘
                         │
              ┌──────────┴──────────┐
              │                     │
         Authenticated         Not Authenticated
              │                     │
              ▼                     ▼
      ┌──────────────┐      ┌──────────────┐
      │  Dashboard   │      │ Onboarding   │
      └──────┬───────┘      └──────┬───────┘
             │                     │
             │              ┌──────┴──────┐
             │              │             │
             │              ▼             ▼
             │         ┌────────┐   ┌────────┐
             │         │ Login  │   │Signup  │
             │         └────┬───┘   └───┬────┘
             │              │           │
             │              └─────┬─────┘
             │                    │
             │                    ▼
             │             ┌──────────────┐
             │             │  Dashboard   │
             │             └──────────────┘
             │
             ├─── Home Tab
             │      ├─ Select Text Debate
             │      │    └─► Topic Selector ─► Text Debate Screen
             │      │                              │
             │      └─ Select Voice Debate         │ End Debate
             │           └─► Topic Selector ─► Voice Debate Screen
             │                                      │
             │                           ┌──────────┘
             │                           │
             │                           ▼
             │                    ┌─────────────┐
             │                    │  Feedback   │
             │                    │   Screen    │
             │                    └──────┬──────┘
             │                           │
             │                           │ View Roadmap
             │                           │
             ├─── History Tab            │
             │      └─ View past debates │
             │         └─► Feedback Details
             │                           │
             ├─── Roadmap Tab ◄──────────┘
             │      ├─ View by Skill
             │      └─ Mark resources complete
             │
             └─── Profile Tab
                    ├─ Edit profile
                    ├─ Settings
                    │   ├─ Toggle theme
                    │   ├─ Adjust voice settings
                    │   └─ Notification preferences
                    └─ Logout ──► Login Screen

Route Guards:
┌────────────────────────────────────────────────┐
│ Unauthenticated users:                         │
│ ├─ Can access: Login, Signup, Onboarding      │
│ └─ Redirected to Login from protected routes  │
│                                                │
│ Authenticated users:                           │
│ ├─ Can access: All app features               │
│ └─ Redirected to Dashboard from auth screens  │
└────────────────────────────────────────────────┘
```

---

## 🧪 Testing Strategy Diagram

```
┌────────────────────────────────────────────────────────────┐
│                    TESTING PYRAMID                          │
└────────────────────────────────────────────────────────────┘

                        ▲
                       ╱│╲
                      ╱ │ ╲
                     ╱  │  ╲
                    ╱   │   ╲ Integration Tests
                   ╱    │    ╲ (End-to-end flows)
                  ╱─────┼─────╲
                 ╱      │      ╲
                ╱       │       ╲
               ╱        │        ╲ Widget Tests
              ╱         │         ╲ (UI components)
             ╱──────────┼──────────╲
            ╱           │           ╲
           ╱            │            ╲
          ╱             │             ╲ Unit Tests
         ╱              │              ╲ (Business logic)
        ╱───────────────┼───────────────╲
       ╱────────────────────────────────╲

Unit Tests (Base - Most tests):
┌────────────────────────────────────────────┐
│ • Model serialization/deserialization      │
│ • Service method logic                     │
│ • Provider state changes                   │
│ • Utility functions                        │
│ • Data validation                          │
└────────────────────────────────────────────┘

Widget Tests (Middle):
┌────────────────────────────────────────────┐
│ • Individual widget rendering              │
│ • User interactions (taps, swipes)         │
│ • State updates triggering UI changes      │
│ • Form validation feedback                 │
│ • Navigation triggers                      │
└────────────────────────────────────────────┘

Integration Tests (Top - Fewer tests):
┌────────────────────────────────────────────┐
│ • Complete user flows                      │
│   ├─ Login → Debate → Feedback → Roadmap  │
│   ├─ Signup → Onboarding → First debate   │
│   └─ Voice debate with AI interaction     │
│ • Multi-screen navigation                  │
│ • Data persistence across sessions         │
└────────────────────────────────────────────┘
```

---

## 📊 Performance Optimization Strategy

```
┌────────────────────────────────────────────────────────────┐
│              PERFORMANCE OPTIMIZATION LAYERS                │
└────────────────────────────────────────────────────────────┘

Layer 1: State Management Optimization
┌──────────────────────────────────────────────────────────┐
│ • Selective notifyListeners() calls                      │
│ • Use Consumer widgets for granular rebuilds             │
│ • Avoid rebuilding entire widget tree                    │
│ • Lazy loading of providers                              │
└──────────────────────────────────────────────────────────┘

Layer 2: Data Caching
┌──────────────────────────────────────────────────────────┐
│ Local Cache (SharedPreferences):                         │
│ ├─ User profile                                          │
│ ├─ Recent debates                                        │
│ ├─ App preferences                                       │
│ └─ Skill statistics                                      │
│                                                          │
│ Memory Cache (Provider state):                           │
│ ├─ Current debate messages                               │
│ ├─ Active user session                                   │
│ └─ UI state                                              │
│                                                          │
│ Strategy: Read local first, fetch remote if needed       │
└──────────────────────────────────────────────────────────┘

Layer 3: API Call Optimization
┌──────────────────────────────────────────────────────────┐
│ • Debounce user input before AI calls                   │
│ • Batch Firestore operations                             │
│ • Use Firestore snapshots for real-time updates          │
│ • Paginate debate history loading                        │
│ • Cancel pending requests on screen exit                 │
└──────────────────────────────────────────────────────────┘

Layer 4: UI Performance
┌──────────────────────────────────────────────────────────┐
│ • Use const constructors where possible                  │
│ • Implement ListView.builder for long lists              │
│ • Optimize image loading with caching                    │
│ • Use RepaintBoundary for complex widgets                │
│ • Avoid expensive operations in build methods            │
└──────────────────────────────────────────────────────────┘

Layer 5: Resource Management
┌──────────────────────────────────────────────────────────┐
│ • Dispose AnimationControllers                           │
│ • Close StreamSubscriptions                              │
│ • Cancel timers and periodic tasks                       │
│ • Release audio resources when not in use                │
│ • Clear temporary cache periodically                     │
└──────────────────────────────────────────────────────────┘

Monitoring:
┌──────────────────────────────────────────────────────────┐
│ • Flutter DevTools for performance profiling             │
│ • Firebase Performance Monitoring                        │
│ • Track API response times                               │
│ • Monitor memory usage                                   │
│ • Measure app startup time                               │
└──────────────────────────────────────────────────────────┘
```

---

## 🎓 Conclusion

This system architecture documentation provides visual representations of:

1. **High-level architecture** - Component relationships
2. **Data flows** - How data moves through the system
3. **Authentication flows** - User login/signup processes
4. **Debate flows** - Conversation management
5. **AI integration** - Gemini API interaction
6. **State management** - Provider pattern implementation
7. **Security layers** - Multi-level security approach
8. **Navigation map** - Screen-to-screen transitions
9. **Testing strategy** - Quality assurance approach
10. **Performance optimization** - Speed and efficiency

These diagrams complement the comprehensive technical documentation and provide a clear understanding of how ArguMentor's systems work together to deliver an engaging AI-powered debate practice experience.

---

**For detailed implementation specifics, refer to `COMPREHENSIVE_DOCUMENTATION.md`**
