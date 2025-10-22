# 🐛 Login Issue Troubleshooting Guide

## Problem: App restarts and shows login screen after successful login

---

## ✅ What I Fixed

### 1. **Updated Router Redirect Logic**
Fixed the router's redirect function in `lib/routes/app_router.dart` to properly handle:
- Splash screen navigation
- Login state transitions
- Protected route access

The router now:
- ✅ Allows splash screen to control its own navigation
- ✅ Redirects logged-in users away from auth pages
- ✅ Redirects non-logged-in users to onboarding
- ✅ Includes detailed logging for debugging

---

## 🔍 How to Debug Your Login Issue

### Step 1: Check Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **aicoach-6950b**
3. Click **"Authentication"** → **"Users"** tab
4. **After trying to login**, check if the user appears here
   - ✅ If YES: Firebase Auth is working
   - ❌ If NO: Firebase Auth is failing

### Step 2: Check Firestore Database

1. In Firebase Console, click **"Firestore Database"**
2. Look for `users` collection
3. Check if your user document exists with the correct UID
   - ✅ If YES: User creation is working
   - ❌ If NO: User creation is failing

### Step 3: Enable Debug Logs

Run your app with verbose logging:

```bash
flutter run --verbose
```

Watch the console output for these key messages:

**Look for these UserProvider messages:**
```
Attempting login with email: [your-email]
Firebase Auth login successful, uid: [some-uid]
User data retrieved: success
Login process completed, isLoggedIn: true
```

**Look for these Router messages:**
```
Router redirect: path=/login, isLoggedIn=false, isLoading=false
Router redirect: path=/dashboard, isLoggedIn=true, isLoading=false
```

### Step 4: Test the Fixed Flow

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test signup first:**
   - Create a NEW account with a NEW email
   - Watch the console logs
   - Expected: Should go to Dashboard

3. **Test login:**
   - Close and reopen the app
   - Login with the account you just created
   - Watch the console logs
   - Expected: Should go to Dashboard

---

## 🔧 Common Issues & Solutions

### Issue 1: "User is null after login"

**Symptom:** Login succeeds in Firebase but `isLoggedIn` remains false

**Cause:** User data not being saved to Firestore or local storage

**Solution:**
```dart
// Check in user_provider.dart line ~230
// Make sure this code runs after successful login:
if (_user == null) {
  // Create user data if it doesn't exist
}
await _storageService.saveUser(_user!);
```

**Fix:** Already implemented in your code ✅

---

### Issue 2: "Router keeps redirecting to splash"

**Symptom:** App shows splash screen repeatedly

**Cause:** Router redirect logic causing infinite loop

**Solution:** ✅ **FIXED** in the router update above

---

### Issue 3: "isLoading stays true"

**Symptom:** App stuck on splash screen

**Cause:** UserProvider initialization not completing

**Solution:** Add timeout to initialization:

```dart
// In user_provider.dart _initializeUser()
Future<void> _initializeUser() async {
  _isLoading = true;
  notifyListeners();
  
  try {
    // ... existing code ...
  } catch (e) {
    print('Error initializing user: $e');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

---

### Issue 4: "context.go() not working"

**Symptom:** Navigation commands don't change the screen

**Cause:** GoRouter not refreshing after state change

**Solution:** ✅ **FIXED** - Router now uses `refreshListenable: userProvider`

---

## 🧪 Test Checklist

Run through this checklist:

- [ ] **Clean build**
  ```bash
  flutter clean && flutter pub get && flutter run
  ```

- [ ] **Firebase Auth enabled**
  - Go to Firebase Console
  - Authentication → Sign-in method
  - Email/Password is **Enabled**

- [ ] **Firestore Database created**
  - Firestore Database exists
  - Started in test mode

- [ ] **Create new account**
  - Use email: test@example.com
  - Use password: Test123456
  - ✅ Should navigate to Dashboard

- [ ] **Check Firebase Console**
  - User appears in Authentication → Users
  - User document in Firestore → users collection

- [ ] **Logout and Login**
  - Logout from profile
  - Login with same credentials
  - ✅ Should navigate to Dashboard

- [ ] **Close and reopen app**
  - Close app completely
  - Reopen app
  - ✅ Should auto-login to Dashboard

---

## 📊 Expected Flow Diagram

```
[Login Screen]
      ↓
User enters email/password
      ↓
Click "Login"
      ↓
UserProvider.login() called
      ↓
Firebase Auth: signInWithEmailAndPassword()
      ↓
✅ Success → Get user data from Firestore
      ↓
Save to local storage
      ↓
Set _user and isLoggedIn = true
      ↓
notifyListeners() → Router gets notified
      ↓
Router redirect() function runs
      ↓
Detects isLoggedIn = true
      ↓
Redirects to Dashboard
      ↓
[Dashboard Screen] ✅
```

---

## 🔍 Debug Commands

### Check current user status:
Add this temporary button to your login screen to debug:

```dart
// Add this in login_screen.dart for debugging
TextButton(
  onPressed: () {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    print('=== DEBUG INFO ===');
    print('isLoggedIn: ${userProvider.isLoggedIn}');
    print('isLoading: ${userProvider.isLoading}');
    print('user: ${userProvider.user?.email}');
    print('Firebase user: ${FirebaseAuth.instance.currentUser?.email}');
  },
  child: Text('DEBUG: Check Status'),
)
```

### Check router state:
The logs should show something like:

```
Router redirect: path=/login, isLoggedIn=false, isLoading=false
Not logged in, trying to access protected page, redirecting to onboarding
---
Router redirect: path=/dashboard, isLoggedIn=true, isLoading=false
No redirect needed
```

---

## 🆘 If Still Not Working

### Quick Fix #1: Disable Router Redirect Temporarily

Comment out the redirect in `app_router.dart`:

```dart
// redirect: (context, state) {
//   // ... all redirect logic ...
// },
```

Then manually navigate in login_screen.dart after successful login:

```dart
if (errorMessage == null) {
  context.go(AppConstants.routeDashboard);
}
```

### Quick Fix #2: Force Reload After Login

In `login_screen.dart`, after successful login:

```dart
if (errorMessage == null) {
  // Force a small delay to ensure state is updated
  await Future.delayed(Duration(milliseconds: 100));
  if (mounted) {
    context.go(AppConstants.routeDashboard);
  }
}
```

### Quick Fix #3: Check Splash Screen Timing

The splash screen waits 500ms before checking user state. If the user state hasn't loaded yet, it might redirect to onboarding. Increase the delay in `splash_screen.dart`:

```dart
await Future.delayed(const Duration(milliseconds: 1000)); // Increased from 500
```

---

## 📝 What to Send Me if Still Broken

If it's still not working, run your app and copy the console output showing:

1. **From Login Button Click:**
   ```
   Login button pressed, calling userProvider.login
   Attempting login with email: [email]
   Firebase Auth login successful, uid: [uid]
   ...
   ```

2. **Router Logs:**
   ```
   Router redirect: path=/login, isLoggedIn=false, isLoading=false
   Router redirect: path=/dashboard, isLoggedIn=true, isLoading=false
   ...
   ```

3. **Any Error Messages:**
   ```
   [ERROR:flutter/runtime/dart_vm_initializer.cc(41)] ...
   ```

Send me these logs and I'll identify the exact issue!

---

## ✅ Success Indicators

You'll know it's working when you see:

1. ✅ Login button shows loading spinner
2. ✅ Console shows: "Login successful, navigating to dashboard"
3. ✅ Console shows: "Router redirect: path=/dashboard, isLoggedIn=true"
4. ✅ Screen changes to Dashboard
5. ✅ User info appears in Firebase Console
6. ✅ Closing and reopening app keeps you logged in

---

## 🎯 Next Steps After Login Works

Once login is working:

1. ✅ Test logout functionality
2. ✅ Test app restart (should auto-login)
3. ✅ Test wrong password error
4. ✅ Test network error handling
5. ✅ Add forgot password feature
6. ✅ Add email verification

---

**Your router is now fixed! Try running the app again and let me know the console output! 🚀**
