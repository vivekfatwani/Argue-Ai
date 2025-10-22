# 🚀 Quick Firebase Setup Steps

## Your app is 95% ready! Just do these 3 things:

### 1️⃣ Enable Email/Password Authentication (2 minutes)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **aicoach-6950b**
3. Click **"Authentication"** → **"Get Started"**
4. Go to **"Sign-in method"** tab
5. Click **"Email/Password"** → Toggle **"Enable"** → **"Save"**

### 2️⃣ Create Firestore Database (2 minutes)

1. In Firebase Console, click **"Firestore Database"**
2. Click **"Create database"**
3. Select **"Start in test mode"**
4. Choose location: **us-central** (or nearest to you)
5. Click **"Enable"**

### 3️⃣ Test Your App! (5 minutes)

```bash
flutter run
```

**Test Signup:**
- Click "Create Account"
- Fill in: Name, Email, Password
- Click "Create Account"
- ✅ Should redirect to Dashboard!

**Test Login:**
- Logout and login with the same credentials
- ✅ Should work!

---

## ✅ What's Already Working

Your code already has:
- ✅ Firebase initialized
- ✅ Login/Signup UI
- ✅ Firebase Authentication logic
- ✅ Firestore data sync
- ✅ User profile management
- ✅ Error handling

---

## 🔐 Security Note

⚠️ **Your API key has been moved to a secure config file!**

The Gemini API key is now in:
- `lib/core/config/api_keys.dart` (actual keys - NOT committed to Git)
- `lib/core/config/api_keys.dart.template` (template - safe to commit)

**Next steps for better security:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. **Revoke** the old API key (it was exposed in your code)
3. **Create a new** API key
4. Update `lib/core/config/api_keys.dart` with the new key

---

## 📖 Full Documentation

See `FIREBASE_SETUP_GUIDE.md` for:
- Complete setup instructions
- Social login integration (Google, Facebook, Apple)
- Firestore security rules
- Troubleshooting guide
- Production deployment checklist

---

## 🆘 Common Issues

**"No user found"** → Enable Email/Password in Firebase Console

**"Permission denied"** → Create Firestore database in test mode

**App crashes** → Run `flutter clean && flutter pub get`

---

**That's it! Your Firebase authentication is ready to use! 🎉**
