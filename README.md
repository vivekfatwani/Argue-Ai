# 🚀 **ArguMentor - Your AI Debate Coach**

**ArguMentor** is a **Flutter-based AI-powered app** designed to help users practice, evaluate, and improve their debating skills. Whether you're a student or a professional, ArguMentor offers real-time text and voice debates with **AI-generated feedback** on clarity, logic, rebuttals, and persuasion. The app also provides a **personalized learning roadmap**, **progress tracking**, and **valuable resources** to help you become a better debater.

---

## 📚 **Documentation**

For detailed technical information and understanding of the system:

- **[📖 Comprehensive Technical Documentation](COMPREHENSIVE_DOCUMENTATION.md)** - Complete guide covering tech stack, architecture, data models, AI integration, and more
- **[🏗️ System Architecture & Flow Diagrams](SYSTEM_ARCHITECTURE.md)** - Visual representations of data flows, component relationships, and system architecture
- **[🚀 Quick Start Guide](QUICK_START.md)** - Get up and running in 5 minutes
- **[🔐 Firebase Setup Guide](FIREBASE_SETUP_GUIDE.md)** - Detailed Firebase configuration instructions
- **[📋 Implementation Summary](SUMMARY.md)** - Overview of what's been implemented

---

## 🌟 **Key Features**

- **AI Debate**: Engage in real-time text or voice debates with an AI-powered debate coach powered by Google Gemini 2.5 Flash
- **Instant Feedback**: Receive detailed scores on clarity, logic, rebuttal strength, and persuasion
- **Personalized Learning Roadmap**: Get AI-generated recommendations based on your performance
- **Progress Tracking**: Track your debate performance, points, levels, and achievements
- **Resource Recommendations**: Access AI-curated articles, videos, and exercises to improve specific skills
- **Profile & History**: Keep a complete history of debates with detailed statistics
- **Voice & Text Modes**: Choose between typing or speaking your arguments
- **Dark Mode**: Eye-friendly dark theme support

---

## 💻 **Tech Stack**

### Frontend & Mobile
- **Flutter 3.7.2+** - Cross-platform mobile framework
- **Dart ^3.7.2** - Programming language

### State Management
- **Provider 6.0.5** - Reactive state management pattern

### Backend & Cloud Services
- **Firebase Core 2.15.1** - Firebase SDK
- **Firebase Auth 4.7.3** - User authentication
- **Cloud Firestore 4.8.5** - NoSQL cloud database
- **Firebase Storage 11.2.6** - File storage

### AI & Machine Learning
- **Google Generative AI 0.1.0** - Gemini API integration
- **Model**: Gemini 2.5 Flash
- **Configuration**: Temperature 0.7, Top K 40, Top P 0.95

### Audio & Voice
- **speech_to_text 7.3.0** - Voice recognition
- **audioplayers 5.2.0** - Audio playback

### UI & Visualization
- **fl_chart 0.63.0** - Charts and graphs
- **flutter_svg 2.0.9** - SVG rendering
- **go_router 12.1.1** - Declarative routing

### Local Storage
- **shared_preferences 2.2.2** - Key-value storage
- **path_provider 2.1.1** - File system access

---

## 🏗️ **Architecture Overview**

ArguMentor follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────┐
│     Presentation Layer          │  ← Screens & Widgets
├─────────────────────────────────┤
│  State Management (Providers)   │  ← Business Logic
├─────────────────────────────────┤
│      Services Layer             │  ← AI, Storage, Audio
├─────────────────────────────────┤
│    Data & Backend Layer         │  ← Firebase, Local Storage
└─────────────────────────────────┘
```

**Key Patterns:**
- **Provider Pattern** for reactive state management
- **Repository Pattern** for data access abstraction
- **Service Layer Pattern** for business logic separation
- **Factory Pattern** for model creation

For detailed architecture diagrams, see [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md).

---

## 🛠 **Installation & Setup**

1. **Clone the repository:**

   ```bash
   git clone https://github.com/vivekfatwani/Argue-Ai.git
   cd Argue-Ai
