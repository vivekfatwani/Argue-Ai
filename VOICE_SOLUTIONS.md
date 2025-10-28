# 🎙️ Professional Voice Solutions for Debate AI

The built-in `flutter_tts` isn't working well for your debate app. Here are **proven external solutions** that will give you professional voice quality with proper pacing and persona.

---

## ⭐ **Option 1: Google Cloud Text-to-Speech** (RECOMMENDED)

### **Why Choose This:**
- **Neural voices** sound 95% human
- Full **SSML control** for pacing, emphasis, pauses
- **Multiple personas** (authoritative, conversational, professional)
- **Reliable** and works on all devices
- **$4/million characters** (~$0.016 per debate)

### **Setup Steps:**

1. **Create Google Cloud Project:**
   ```
   https://console.cloud.google.com
   → Create Project
   → Enable "Cloud Text-to-Speech API"
   ```

2. **Get API Key:**
   ```
   APIs & Services → Credentials → Create Credentials → API Key
   Copy the key
   ```

3. **Add to pubspec.yaml:**
   ```yaml
   dependencies:
     http: ^1.1.0
   ```

4. **Add API key to your code:**
   ```dart
   // In google_tts_service.dart (already created)
   static const String API_KEY = 'YOUR_KEY_HERE';
   ```

5. **Use in voice_debate_screen.dart:**
   ```dart
   // Replace AudioProvider with GoogleTTSService
   final googleTTS = GoogleTTSService();
   await googleTTS.speak(aiResponse);
   ```

### **Voice Options:**
- `en-US-Neural2-J` - Professional male (authoritative) ⭐
- `en-US-Neural2-F` - Professional female (clear)
- `en-US-Studio-O` - Natural conversational male
- `en-US-Neural2-D` - Warm, engaging male

### **Cost:** ~$0.02 per debate (very affordable)

---

## 🎯 **Option 2: ElevenLabs API** (Best Quality)

### **Why Choose This:**
- **Best quality** voices (most human-like)
- Can clone specific voice personas
- Emotion control (confident, assertive, calm)
- Perfect for debate scenarios

### **Setup:**

1. **Get API Key:**
   ```
   https://elevenlabs.io
   → Sign up (Free tier: 10k characters/month)
   → Get API key from settings
   ```

2. **Add package:**
   ```yaml
   dependencies:
     http: ^1.1.0
   ```

3. **Code:**
   ```dart
   import 'dart:convert';
   import 'package:http/http.dart' as http;
   
   class ElevenLabsTTS {
     static const API_KEY = 'YOUR_ELEVENLABS_KEY';
     static const VOICE_ID = 'pNInz6obpgDQGcFmaJgB'; // Adam (professional male)
     
     Future<void> speak(String text) async {
       final response = await http.post(
         Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID'),
         headers: {
           'xi-api-key': API_KEY,
           'Content-Type': 'application/json',
         },
         body: jsonEncode({
           'text': text,
           'model_id': 'eleven_monolingual_v1',
           'voice_settings': {
             'stability': 0.75,      // More consistent
             'similarity_boost': 0.85, // More natural
           }
         }),
       );
       
       // Play audio (similar to Google TTS)
     }
   }
   ```

### **Voice Options:**
- Adam - Professional debater voice
- Antoni - Clear, authoritative
- Arnold - Deep, confident

### **Cost:** Free tier: 10k chars/month, Paid: $5/month

---

## 🚀 **Option 3: Azure Speech Services** (Enterprise)

### **Why Choose This:**
- Microsoft's neural voices
- Great multilingual support
- SSML support
- Very reliable

### **Setup:**

1. **Create Azure Account:**
   ```
   https://azure.microsoft.com/free
   → Create Speech Services resource
   ```

2. **Get Key:**
   ```
   Copy key and region
   ```

3. **Add package:**
   ```yaml
   dependencies:
     http: ^1.1.0
   ```

4. **Code:**
   ```dart
   class AzureTTS {
     static const KEY = 'YOUR_AZURE_KEY';
     static const REGION = 'eastus';
     
     Future<void> speak(String text) async {
       final response = await http.post(
         Uri.parse('https://$REGION.tts.speech.microsoft.com/cognitiveservices/v1'),
         headers: {
           'Ocp-Apim-Subscription-Key': KEY,
           'Content-Type': 'application/ssml+xml',
           'X-Microsoft-OutputFormat': 'audio-16khz-128kbitrate-mono-mp3',
         },
         body: '''
           <speak version='1.0' xml:lang='en-US'>
             <voice name='en-US-GuyNeural'>
               <prosody rate="-10%" pitch="-5%">
                 $text
               </prosody>
             </voice>
           </speak>
         ''',
       );
       // Play audio
     }
   }
   ```

### **Cost:** Free tier: 5 million chars/month

---

## 💡 **Option 4: Pre-generate Responses** (Offline)

### **Why Choose This:**
- No API costs
- Works offline
- Consistent quality

### **How:**
1. Generate common AI responses in advance
2. Use high-quality TTS (like Google Cloud) to create MP3 files
3. Store in `assets/voices/`
4. Play appropriate response based on context

**Best for:** Limited debate topics with predictable responses

---

## 📊 **Comparison Table:**

| Solution | Quality | Cost | Setup | Best For |
|----------|---------|------|-------|----------|
| **Google Cloud TTS** | ⭐⭐⭐⭐ | $4/1M chars | Easy | **Recommended** ⭐ |
| **ElevenLabs** | ⭐⭐⭐⭐⭐ | Free/Paid | Easy | Best quality |
| **Azure Speech** | ⭐⭐⭐⭐ | Free tier | Medium | Enterprise |
| **Pre-generated** | ⭐⭐⭐⭐⭐ | One-time | Hard | Offline/Fixed |
| **flutter_tts** | ⭐⭐ | Free | Done | Not working |

---

## 🎯 **My Recommendation:**

**Use Google Cloud Text-to-Speech** because:
1. ✅ Easy to set up (10 minutes)
2. ✅ Excellent voice quality
3. ✅ Full SSML control for pacing
4. ✅ Very affordable ($0.02/debate)
5. ✅ Works reliably on all devices
6. ✅ I've already created the code for you!

---

## 🚀 **Quick Start (Google Cloud TTS):**

```bash
# 1. Add dependency
flutter pub add http

# 2. Get API key from Google Cloud Console

# 3. Add to google_tts_service.dart:
static const String API_KEY = 'your-key-here';

# 4. Use in voice_debate_screen.dart:
final googleTTS = GoogleTTSService();
await googleTTS.speak(aiMessage);
```

---

## 🎤 **Voice Persona Control:**

All these services let you control:
- **Speed**: Slow, measured debate pace
- **Pitch**: Lower for authority
- **Emphasis**: Stress important words
- **Pauses**: Natural breathing between sentences

**Example SSML (Google/Azure):**
```xml
<speak>
  <prosody rate="slow" pitch="-2st">
    I strongly disagree with your point.
    <break time="800ms"/>
    Consider the evidence from recent studies.
  </prosody>
</speak>
```

This gives you the professional debate voice you need! 🎯
