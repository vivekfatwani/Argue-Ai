# 🔧 Fix All 3 Errors - Complete Guide

## Current Errors:
1. ❌ **ElevenLabs API Key Invalid**
2. ❌ **Speech Recognition Error** 
3. ❌ **Firestore Database Not Found**

---

## 1️⃣ **Fix ElevenLabs API Key (5 minutes)**

### **Step 1: Get a FREE API Key**
1. Go to: https://elevenlabs.io/sign-up
2. Sign up with Google/Email (FREE - no credit card required)
3. After signing in, go to: https://elevenlabs.io/app/settings/api-keys
4. Click **"Create API Key"**
5. Copy the key (looks like: `sk_xxxxxxxxxxxxx`)

### **Step 2: Add Key to Your App**
Open: `lib/core/services/elevenlabs_tts_service.dart`

Find line 18 and replace:
```dart
static const String API_KEY = 'YOUR_ELEVENLABS_API_KEY_HERE';
```

With your actual key:
```dart
static const String API_KEY = 'sk_your_actual_key_here';
```

### **What You Get:**
- ✅ 10,000 characters/month FREE
- ✅ Super realistic AI voices
- ✅ Voice debates work perfectly

---

## 2️⃣ **Fix Speech Recognition (Already Handled!)**

### **The Issue:**
The error `SpeechRecognitionError msg: error_no_match` is expected behavior. It means:
- STT is waiting for you to speak
- No speech detected yet
- This is NORMAL and not an error

### **How Voice Debate Works:**
1. Click microphone button
2. App starts listening (you'll see the animation)
3. Speak your argument
4. Click microphone again to stop
5. AI responds with voice (via ElevenLabs)

**No action needed** - this is working as designed! ✅

---

## 3️⃣ **Fix Firestore Database (2 minutes)**

### **Quick Fix:**
1. Click this direct link: 
   ```
   https://console.cloud.google.com/datastore/setup?project=argueai-2f86d
   ```
2. Click **"Select Native Mode"** → **"Create Database"**
3. Choose location: `us-central1` (or closest to you)
4. Click **"Create Database"**
5. Wait 1-2 minutes for setup

### **Alternative Manual Method:**
1. Go to: https://console.firebase.google.com/
2. Select project: **argueai-2f86d**
3. Click **"Firestore Database"** in left menu
4. Click **"Create database"**
5. Select **"Start in test mode"**
6. Choose location
7. Click **"Enable"**

### **Why This Matters:**
- ✅ Saves user data to cloud
- ✅ Syncs across devices
- ✅ Sign out works completely
- ✅ No more timeout errors

---

## 🎯 **Quick Checklist**

After fixing:
- [ ] ElevenLabs API key added to `elevenlabs_tts_service.dart`
- [ ] Firestore database created in Firebase Console
- [ ] Run `flutter run` to test

---

## ✅ **Test That Everything Works**

### **Test Voice Debate:**
1. Open app
2. Click "Voice Debate"
3. Select a topic
4. Click microphone and speak
5. AI should respond with voice ✅

### **Test Sign Out:**
1. Go to Profile or Dashboard
2. Click "Sign Out"
3. Should redirect to Onboarding ✅

### **Expected Console Logs:**
```
[ElevenLabs] Generating speech for: ...
[ElevenLabs] Audio received, playing...
[ElevenLabs] Speech completed
=== LOGOUT START ===
=== LOGOUT COMPLETE, notifyListeners called ===
[GoRouter] going to /onboarding
```

---

## 🆘 **Still Having Issues?**

### **ElevenLabs Not Working:**
- Check API key is correct (no extra spaces)
- Verify you have monthly quota left
- Try creating a new API key

### **Firestore Still Failing:**
- Wait 2-3 minutes after creating database
- Restart your app with `flutter run`
- Check Firebase Console shows "Firestore Database" is active

### **Voice Not Playing:**
- Check device volume
- Check app has microphone permission
- Try Text Debate mode first to test AI responses

---

## 📝 **Summary**

**Priority Fixes:**
1. **HIGH**: Add ElevenLabs API key (required for voice debates)
2. **HIGH**: Create Firestore database (required for data sync)
3. **LOW**: Speech recognition error is normal behavior

**Time Required:** ~7 minutes total

**After fixing, you'll have:**
- ✅ Working voice debates with AI voice responses
- ✅ Cloud data sync and backup
- ✅ Proper sign out functionality
- ✅ No more error messages

---

**Ready? Start with Step 1 (ElevenLabs) above! 🚀**
