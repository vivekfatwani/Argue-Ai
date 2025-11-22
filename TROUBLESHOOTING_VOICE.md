# Voice Not Working - Troubleshooting Guide

## If AI voice is not speaking in the APK:

### 1. **Check Internet Connection**
- The app requires internet to:
  - Get AI responses from Google Gemini
  - Download TTS voices (first time)
- Make sure you have a stable internet connection

### 2. **Install Google Text-to-Speech**
The app uses your phone's TTS engine. If voice doesn't work:

1. Open **Google Play Store**
2. Search for **"Google Text-to-Speech"**
3. Install or Update it
4. Go to Phone **Settings** → **Language & Input** → **Text-to-Speech**
5. Select **Google Text-to-Speech Engine**
6. Download **English (US)** voice data

### 3. **Grant Permissions**
When you first open the app:
- Allow **Microphone** permission (for speech-to-text)
- The app also needs **Internet** access (usually auto-granted)

### 4. **Test TTS on Your Phone**
To verify TTS works on your device:
1. Go to **Settings** → **Accessibility** → **Text-to-Speech**
2. Tap **"Listen to an example"**
3. If this doesn't speak, your phone's TTS needs setup

### 5. **Restart the App**
- Close the app completely
- Clear from recent apps
- Reopen and try voice debate again

### 6. **Check Phone Volume**
- Make sure media volume is turned up
- Not muted or on silent mode

## Still Not Working?

### Debug Steps:
1. Try **Text Debate** mode first - does AI respond?
   - If NO: Internet or API issue
   - If YES: TTS issue
   
2. Does voice input work (speech-to-text)?
   - If NO: Microphone permission issue
   - If YES: Only TTS output issue

### Common Issues:

| Symptom | Cause | Solution |
|---------|-------|----------|
| AI never responds | No internet or API key issue | Check connection, rebuild APK |
| AI responds but no voice | TTS not installed | Install Google TTS |
| Can't use microphone | Permission denied | Grant mic permission in settings |
| Voice very slow | TTS settings | Adjust in phone TTS settings |

## For Developers:

The app now includes:
- ✅ INTERNET permission in AndroidManifest
- ✅ Fallback error handling for TTS
- ✅ Automatic voice selection

To rebuild with fixes:
```bash
flutter clean
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`
