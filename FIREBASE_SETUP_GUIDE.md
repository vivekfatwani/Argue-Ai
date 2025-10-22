# 🔥 Firebase Authentication Setup Guide for ArguMentor

## ✅ Current Status: ALMOST COMPLETE!

Your app is **95% ready** to use Firebase Authentication! Here's what you need to do to make it fully functional.

---

## 📋 What's Already Done ✓

1. ✅ Firebase packages installed (`firebase_core`, `firebase_auth`, `cloud_firestore`)
2. ✅ Firebase initialized in `main.dart`
3. ✅ `firebase_options.dart` generated with your project config
4. ✅ `google-services.json` added for Android
5. ✅ Login/Signup screens UI created
6. ✅ `UserProvider` with complete Firebase Auth logic
7. ✅ Firestore database integration for user data

---

## 🚀 Steps to Complete Firebase Setup

### **Step 1: Enable Authentication Methods in Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **aicoach-6950b**
3. Click on **"Authentication"** in the left sidebar
4. Click on **"Get Started"** if you haven't already
5. Go to **"Sign-in method"** tab
6. Enable the following providers:
   - ✅ **Email/Password** - Click and toggle "Enable"
   - ✅ **Google** (optional - for "Continue with Google")
   - ✅ **Facebook** (optional - for "Continue with Facebook")
   - ✅ **Apple** (optional - for "Continue with Apple")

### **Step 2: Enable Firestore Database**

1. In Firebase Console, click **"Firestore Database"**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 31);
       }
     }
   }
   ```
4. Click **"Next"** and choose a location (e.g., `us-central`)
5. Click **"Enable"**

### **Step 3: Update Firestore Security Rules (Production-Ready)**

Once testing is done, update your Firestore rules for better security:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow users to read/write their own subcollections
      match /debates/{debateId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /resources/{resourceId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### **Step 4: Test Your Authentication**

1. **Run your app:**
   ```bash
   flutter run
   ```

2. **Test Signup:**
   - Open the app
   - Go to "Create Account" (Signup screen)
   - Fill in: Name, Email, Password, Confirm Password
   - Click "Create Account"
   - ✅ You should be redirected to the Dashboard

3. **Test Login:**
   - Logout (if logged in)
   - Enter the email and password you just created
   - Click "Login"
   - ✅ You should be redirected to the Dashboard

4. **Check Firebase Console:**
   - Go to **Authentication > Users** tab
   - ✅ You should see your newly created user

5. **Check Firestore:**
   - Go to **Firestore Database**
   - ✅ You should see a `users` collection with your user document

---

## 🔐 Security Recommendations

### **1. Remove Hardcoded API Key from Code**

⚠️ **CRITICAL**: Your Gemini API key is exposed in `main.dart` line 28!

Create a secure config file:

```dart
// lib/core/config/api_keys.dart (Add this to .gitignore!)
class ApiKeys {
  static const String geminiApiKey = 'AIzaSyC2BIc0pU7zxUCplaA1q6LYwJwtrV2AlYE';
}
```

Update `main.dart`:
```dart
import 'package:argumentor/core/config/api_keys.dart';

// Replace line 28 with:
final aiService = AIService(ApiKeys.geminiApiKey);
```

Add to `.gitignore`:
```
# API Keys (DO NOT COMMIT)
lib/core/config/api_keys.dart
```

### **2. Revoke Exposed API Key**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services > Credentials**
3. Find and **delete** the exposed API key
4. **Create a new API key**
5. Update your code with the new key

---

## 🧪 Testing Checklist

- [ ] Firebase Console: Authentication enabled (Email/Password)
- [ ] Firebase Console: Firestore Database created
- [ ] App: Can create new account (signup)
- [ ] App: Can login with created account
- [ ] App: Can logout
- [ ] Firebase Console: New user appears in Authentication > Users
- [ ] Firebase Console: User document created in Firestore > users collection
- [ ] App: User data persists after closing and reopening
- [ ] App: Proper error messages for wrong password/email

---

## 🐛 Common Issues & Solutions

### **Issue 1: "No user found" error**
**Solution**: Make sure Email/Password authentication is enabled in Firebase Console.

### **Issue 2: "Permission denied" in Firestore**
**Solution**: Check your Firestore security rules. For development, use test mode rules.

### **Issue 3: App crashes on login/signup**
**Solution**: Run `flutter clean && flutter pub get` and rebuild.

### **Issue 4: "Network error" on authentication**
**Solution**: 
- Check internet connection
- Make sure `google-services.json` is in `android/app/`
- Run `flutter clean` and rebuild

---

## 📱 Optional: Enable Social Login

### **Google Sign-In**

1. Add dependency in `pubspec.yaml`:
   ```yaml
   google_sign_in: ^6.1.5
   ```

2. Enable Google Sign-In in Firebase Console

3. Add SHA-1 fingerprint to Firebase:
   ```bash
   cd android
   ./gradlew signingReport
   ```

### **Facebook Sign-In**

1. Add dependency:
   ```yaml
   flutter_facebook_auth: ^6.0.3
   ```

2. Create Facebook App at [developers.facebook.com](https://developers.facebook.com)
3. Enable Facebook Sign-In in Firebase Console

### **Apple Sign-In**

1. Add dependency:
   ```yaml
   sign_in_with_apple: ^5.0.0
   ```

2. Enable Apple Sign-In in Firebase Console
3. Configure in Apple Developer Console

---

## 📊 Firebase Firestore Data Structure

Your app uses this structure:

```
users (collection)
  ├── {userId} (document)
      ├── name: "John Doe"
      ├── email: "john@example.com"
      ├── createdAt: Timestamp
      ├── lastActive: Timestamp
      ├── points: 0
      ├── skills: {}
      ├── completedResources: []
      ├── preferences: {}
      │
      ├── debates (subcollection)
      │   └── {debateId} (document)
      │       ├── topic: "..."
      │       ├── score: 85
      │       └── ...
      │
      └── resources (subcollection)
          └── {resourceId} (document)
              ├── title: "..."
              └── completed: true
```

---

## 🎯 Next Steps After Setup

1. ✅ Test authentication thoroughly
2. ✅ Set up proper Firestore security rules
3. ✅ Remove hardcoded API keys
4. ✅ Add forgot password functionality
5. ✅ Add email verification
6. ✅ Add profile picture upload (Firebase Storage)
7. ✅ Implement social login (Google, Facebook, Apple)

---

## 📞 Need Help?

- Firebase Documentation: https://firebase.google.com/docs/auth
- FlutterFire Documentation: https://firebase.flutter.dev/
- Common Issues: https://stackoverflow.com/questions/tagged/firebase+flutter

---

**Your app is ready to go! Just enable Email/Password authentication in Firebase Console and start testing! 🚀**
