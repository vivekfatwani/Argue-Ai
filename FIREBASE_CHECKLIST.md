# ✅ Firebase Setup Checklist for ArguMentor

Print this checklist and check off each item as you complete it!

---

## 📱 Pre-Setup Verification

- [x] ✅ Flutter installed and working
- [x] ✅ Firebase project created (aicoach-6950b)
- [x] ✅ `firebase_options.dart` file exists
- [x] ✅ `google-services.json` in `android/app/`
- [x] ✅ Firebase packages in `pubspec.yaml`
- [x] ✅ Login/Signup screens created
- [x] ✅ UserProvider with Firebase logic

---

## 🔥 Firebase Console Setup

### Step 1: Enable Authentication
- [ ] Open https://console.firebase.google.com/
- [ ] Select project: **aicoach-6950b**
- [ ] Click **"Authentication"** in sidebar
- [ ] Click **"Get Started"** button
- [ ] Go to **"Sign-in method"** tab
- [ ] Find **"Email/Password"** provider
- [ ] Click to expand it
- [ ] Toggle **"Enable"** switch ON
- [ ] Click **"Save"** button
- [ ] ✅ Email/Password should now show "Enabled"

### Step 2: Create Firestore Database
- [ ] Click **"Firestore Database"** in sidebar
- [ ] Click **"Create database"** button
- [ ] Select **"Start in test mode"** radio button
- [ ] Click **"Next"**
- [ ] Choose location: **us-central** (or nearest region)
- [ ] Click **"Enable"** button
- [ ] Wait for database creation (~30 seconds)
- [ ] ✅ Database should show "Cloud Firestore" section

### Step 3: Verify Configuration
- [ ] Go back to **"Project Overview"**
- [ ] Click gear icon ⚙️ → **"Project settings"**
- [ ] Scroll to **"Your apps"** section
- [ ] Verify Android app is listed
- [ ] Package name should be: `com.example.argumentor`
- [ ] ✅ Configuration files downloaded

---

## 💻 Code Updates (Already Done!)

- [x] ✅ Created `lib/core/config/api_keys.dart`
- [x] ✅ Updated `main.dart` to use secure config
- [x] ✅ Added API keys to `.gitignore`
- [x] ✅ Created template file for team members

---

## 🧪 Testing Your App

### Test 1: Run the App
- [ ] Open terminal in project folder
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter run`
- [ ] ✅ App launches without errors

### Test 2: Create Account (Signup)
- [ ] Click **"Sign Up"** or **"Create Account"**
- [ ] Fill in **Full Name**: Test User
- [ ] Fill in **Email**: test@example.com
- [ ] Fill in **Password**: Test123456
- [ ] Fill in **Confirm Password**: Test123456
- [ ] Click **"Create Account"** button
- [ ] ✅ No error appears
- [ ] ✅ Redirected to Dashboard screen

### Test 3: Verify in Firebase Console
- [ ] Go to Firebase Console
- [ ] Click **"Authentication"**
- [ ] Click **"Users"** tab
- [ ] ✅ Your test user appears in the list
- [ ] Click **"Firestore Database"**
- [ ] ✅ `users` collection exists
- [ ] ✅ Your user document is inside

### Test 4: Logout and Login
- [ ] In the app, click **"Logout"** (in profile/settings)
- [ ] ✅ Redirected to Login screen
- [ ] Enter **Email**: test@example.com
- [ ] Enter **Password**: Test123456
- [ ] Click **"Login"** button
- [ ] ✅ Successfully logged in
- [ ] ✅ Redirected to Dashboard

### Test 5: Error Handling
- [ ] Try logging in with **wrong password**
- [ ] ✅ Shows error: "Wrong password"
- [ ] Try logging in with **non-existent email**
- [ ] ✅ Shows error: "No user found"
- [ ] Try signing up with **already used email**
- [ ] ✅ Shows error: "Email already in use"

### Test 6: Data Persistence
- [ ] Login to your account
- [ ] Close the app completely
- [ ] Reopen the app
- [ ] ✅ Still logged in (user data persists)

---

## 🔐 Security Checklist

### API Key Security
- [x] ✅ Moved API key to separate config file
- [ ] ⚠️ **URGENT**: Revoke exposed API key in Google Cloud Console
- [ ] Create new Gemini API key
- [ ] Update `lib/core/config/api_keys.dart` with new key
- [ ] Verify `api_keys.dart` is in `.gitignore`
- [ ] ✅ Template file (`api_keys.dart.template`) created

### Firebase Security
- [ ] Update Firestore Security Rules (after testing)
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /users/{userId} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
  ```
- [ ] Enable **Email Verification** (optional)
- [ ] Set up **Password Reset** flow
- [ ] Add **reCAPTCHA** for production

---

## 📊 Data Structure Verification

Go to Firestore Database and verify this structure exists:

```
✅ users (collection)
    ├── ✅ {userId} (document - auto-generated)
        ├── name: "Test User"
        ├── email: "test@example.com"
        ├── createdAt: (timestamp)
        ├── lastActive: (timestamp)
        ├── points: 0
        ├── skills: {}
        ├── completedResources: []
        └── preferences: {}
```

- [ ] `users` collection exists
- [ ] User document has correct fields
- [ ] Timestamps are properly formatted
- [ ] ✅ Data structure is correct

---

## 🎯 Optional Enhancements

### Email Verification
- [ ] Enable in Firebase Console
- [ ] Update code to send verification email
- [ ] Require email verification before access

### Password Reset
- [ ] Add "Forgot Password?" functionality
- [ ] Test password reset email
- [ ] Update UI for password reset flow

### Social Login
- [ ] Add Google Sign-In
- [ ] Add Facebook Login
- [ ] Add Apple Sign-In

### Profile Features
- [ ] Add profile picture upload
- [ ] Enable Firebase Storage
- [ ] Implement image upload logic

---

## ✅ Final Verification

- [ ] All tests passed ✅
- [ ] No console errors
- [ ] Authentication works smoothly
- [ ] Data saves to Firestore
- [ ] User experience is smooth
- [ ] API keys are secure
- [ ] Ready for deployment! 🚀

---

## 📝 Notes

**Date Completed**: _______________

**Issues Encountered**:
- ________________________________________
- ________________________________________
- ________________________________________

**Solutions Applied**:
- ________________________________________
- ________________________________________
- ________________________________________

---

## 🆘 If You Have Issues

1. **Check Firebase Console**: Make sure Email/Password is enabled
2. **Check Firestore**: Make sure database is created
3. **Run**: `flutter clean && flutter pub get`
4. **Check Logs**: Look for error messages in console
5. **Review**: `FIREBASE_SETUP_GUIDE.md` for detailed troubleshooting

---

**🎉 Congratulations! Your Firebase Authentication is now fully set up!**
