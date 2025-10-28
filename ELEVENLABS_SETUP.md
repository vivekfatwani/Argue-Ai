# 🎙️ ElevenLabs Setup Guide - FREE Voice for Your Debate App

## Why ElevenLabs?
✅ **Completely FREE** - 10,000 characters per month (about 150+ debates)  
✅ **NO credit card required** - Just email signup  
✅ **Best AI voice quality** - Sounds 98% human  
✅ **Perfect for debates** - Professional, authoritative voices  
✅ **Works for students** - No special accounts needed  

---

## 📋 Step-by-Step Setup (5 minutes)

### 1️⃣ Sign Up (2 minutes)

1. Go to **https://elevenlabs.io**
2. Click **"Get Started Free"**
3. Sign up with:
   - Email (any email works)
   - OR Google account
   - OR GitHub account
4. **No credit card needed!** ✅

### 2️⃣ Get Your API Key (1 minute)

1. After signing up, you'll land on the dashboard
2. Click your **profile icon** (top right)
3. Click **"Profile + API Key"**
4. Copy your API key (looks like: `sk_1234567890abcdef...`)

### 3️⃣ Add API Key to Your App (1 minute)

1. Open: `lib/core/services/elevenlabs_tts_service.dart`
2. Find line 19:
   ```dart
   static const String API_KEY = 'YOUR_ELEVENLABS_API_KEY_HERE';
   ```
3. Replace with your actual key:
   ```dart
   static const String API_KEY = 'sk_1234567890abcdef...';
   ```
4. **Save the file** ✅

### 4️⃣ Run Your App (1 minute)

```bash
flutter pub get
flutter run
```

**That's it!** Your AI will now speak with professional voice quality! 🎉

---

## 🎤 Voice Options

The default voice is **Adam** (professional male, authoritative).

To change voice, add this before the debate starts:

```dart
_elevenLabsTTS.setVoice(ElevenLabsTTS.VOICE_ANTONI); // Clear, well-paced
```

**Available voices:**
- `VOICE_ADAM` ⭐ - Professional male (default) - Best for debates
- `VOICE_ANTONI` - Clear, well-paced male
- `VOICE_ARNOLD` - Deep, confident male
- `VOICE_BELLA` - Professional female

---

## 📊 Free Tier Limits

| Feature | Free Tier |
|---------|-----------|
| **Characters/month** | 10,000 |
| **Debates** | ~150 (based on 60-70 chars per response) |
| **Voice quality** | Full Neural AI |
| **Expiration** | Never! Free forever |

**Example:** If each AI response is ~60 characters, you get **166 debates per month** for FREE!

---

## ⚠️ Troubleshooting

### "Invalid API key" error:
1. Check you copied the FULL key (starts with `sk_`)
2. No extra spaces before/after the key
3. Key is inside single quotes `'sk_...'`

### "Monthly quota exceeded":
- You've used 10k characters this month
- Resets on the 1st of next month
- OR upgrade to paid plan ($5/month for 30k chars)

### "No sound playing":
1. Check device volume
2. Try on a different device
3. Check terminal for error messages

---

## 🎯 What Changed in Your Code

✅ Created: `lib/core/services/elevenlabs_tts_service.dart`  
✅ Modified: `lib/features/debate/voice_debate_screen.dart`  
✅ Added: ElevenLabs integration (replaces flutter_tts)  

**Old way (flutter_tts):**
```dart
await audioProvider.speak(message); // Robotic, fast, unreliable
```

**New way (ElevenLabs):**
```dart
await _elevenLabsTTS.speak(message); // Human-like, perfect pace! ✨
```

---

## 🚀 Next Steps

1. **Test it out:** Start a voice debate and hear the difference!
2. **Adjust settings:** If you want slower/faster speech, edit `voice_settings` in `elevenlabs_tts_service.dart`
3. **Monitor usage:** Check your character count at https://elevenlabs.io/app/usage

---

## 💡 Pro Tips

- **Each sentence** uses ~50-70 characters
- **Keep AI responses short** (under 40 words) to save quota
- **Voice quality scales** - longer text = better naturalness
- **Adam voice** is best for debates (authoritative tone)

---

## 📞 Need Help?

- ElevenLabs Docs: https://elevenlabs.io/docs
- Support: support@elevenlabs.io
- Discord: https://discord.gg/elevenlabs

---

**You're all set!** 🎉 Your debate app now has **professional AI voice** - completely FREE! 🚀
