🧠 ArguMentor — AI-Powered Debate Coach
🚀 Project Description
ArguMentor is a Flutter-based mobile application that helps users improve their debating skills through AI-driven real-time debates (text/voice), personalized feedback, and skill-specific learning roadmaps.

🔥 Problem Statement
Practicing debates can be frustrating without tailored feedback. While grammar and general speaking tools exist, there is no proper feedback loop for argument structure, rebuttal strength, or clarity. ArguMentor solves this by offering:

Real-time debates against AI (text or voice)

Feedback on debating components (clarity, logic, rebuttal, persuasion)

Personalized roadmap for skill improvement

Engaging and motivational gamified scoring system

🧰 Tech Stack
Layer	Technology
Frontend	Flutter
State Management	Provider / Riverpod
Backend AI	Gemini API (for debate + feedback)
Voice Recognition	speech_to_text (Flutter plugin)
Text-to-Speech	flutter_tts
Audio Playback	just_audio
Animations	lottie_flutter
Storage	SharedPreferences (local)
Routing	go_router or auto_route
Database	Firebase (optional for auth/history)
UI Design Tools	Figma (for UI mockups)
🎨 UI/UX Goals
Minimal, clean, elegant interface

Focus on readability and interactivity

Voice feedback animation with waveform

Real-time score animations

Gamified progress with badges and points

Dark mode and accessibility friendly

📦 Architecture
Modular Feature-Based Structure

bash
Copy
Edit
lib/
├── core/         # Constants, themes, utilities
├── features/     # Each feature in its own module
├── routes/       # Navigation setup
├── widgets/      # Reusable components
└── main.dart     # App entry point
📆 Development Phases
✅ Phase 1: Project Setup + Onboarding UI
Goals:

Setup Flutter environment

Create onboarding flow

Implement signup/login UI (Google/Firebase Auth)

UI Screens:

OnboardingScreen

LoginScreen

SignUpScreen

✅ Phase 2: Dashboard + Navigation
Goals:

Implement bottom navigation bar

Create dashboard with options:

Text Debate

Voice Debate

History

Profile

UI Screens:

DashboardScreen

BottomNavigationBar

Placeholder UI for other screens

✅ Phase 3: Debate Module
Goals:

Text-based AI chat debate

Voice-to-text AI debate with TTS

Real-time rendering of arguments

Display “speech bubbles” for both sides

Logic:

Send user input to Gemini API

Use debounce & stop condition for AI replies

Display typing animations

UI Screens:

DebateScreen

VoiceModeScreen

TextModeScreen

Widgets:

DebateBubble

MicrophoneButton

AnimatedTypingIndicator

✅ Phase 4: Feedback Module
Goals:

Analyze user debate with AI

Breakdown score by:

Clarity

Logic

Rebuttal Quality

Persuasiveness

Display graphical scorecard

UI Screens:

FeedbackScreen

SkillBreakdownComponent

Widgets:

RadarChart (using fl_chart)

ScoreCard

RecommendationsList

✅ Phase 5: Personalized Roadmap
Goals:

Use feedback to recommend:

Videos

Quizzes

Mini exercises

Mark completed resources

Enable “level up” badges

UI Screens:

RoadmapScreen

ResourceDetailScreen

Widgets:

SkillCard

ProgressTracker

BadgeEarnedDialog

✅ Phase 6: Profile + History
Goals:

User profile with stats

Debate history with:

Date

Topic

Score Summary

UI Screens:

ProfileScreen

HistoryScreen

Widgets:

HistoryCard

AvatarCustomization

SettingsTile

✅ Phase 7: Gamification Layer
Goals:

XP and point-based scoring

Leaderboard (optional Firebase)

Badges for milestones

Confetti animation on level-up

Widgets:

XPBar

BadgeCarousel

ConfettiCelebration

📱 Final UI Summary
Screen	UI Highlights
Onboarding	Carousel with animations
Dashboard	Clean cards with icons
Debate (Text)	Chat UI with real-time typing
Debate (Voice)	Waveform + mic button + subtitles
Feedback	Graphs + color-coded cards
Roadmap	Interactive tiles and checklists
Profile	Avatar, XP bar, performance graphs
History	Expandable list with past debates
🧪 Testing
Unit Testing for controllers (feedback, debate)

Widget Testing for UI components

Integration Testing for login-debate-feedback flow

📈 Future Enhancements
Multi-user real-time debate rooms (with socket)

Leaderboard with country ranks

Tournament mode

Offline Practice Mode (cached topics)


