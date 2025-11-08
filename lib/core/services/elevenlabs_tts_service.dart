import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

/// ElevenLabs Text-to-Speech Service
/// FREE TIER: 10,000 characters per month
/// Best quality AI voices - sounds very human
/// 
/// Setup:
/// 1. Go to https://elevenlabs.io and sign up (FREE, no credit card)
/// 2. Get your API key from Settings → API Keys
/// 3. Paste it below in API_KEY constant
class ElevenLabsTTS {
  // 🔑 ADD YOUR ELEVENLABS API KEY HERE:
  // Get it from: https://elevenlabs.io/app/settings/api-keys
  static const String API_KEY = 'sk_6d5f472c802bdebbf67323414bdd68e8003198c3a96b8746';
  
  // ⚠️ YOUR OLD KEY WAS INVALID/REVOKED
  // Get a NEW FREE key from: https://elevenlabs.io/sign-up
  
  // Voice IDs (pre-selected professional voices)
  static const String VOICE_ADAM = 'pNInz6obpgDQGcFmaJgB'; // Professional male - authoritative
  static const String VOICE_ANTONI = 'ErXwobaYiN019PkySvjV'; // Clear, well-paced male
  static const String VOICE_ARNOLD = 'VR6AewLTigWG4xSOukaG'; // Deep, confident male
  static const String VOICE_BELLA = 'EXAVITQu4vr4xnSDxMaL'; // Professional female
  
  // Using Adam by default - best for debate
  static const String DEFAULT_VOICE = VOICE_ADAM;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  
  bool get isSpeaking => _isSpeaking;
  
  /// Speak text using ElevenLabs TTS
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Check if API key is set
    if (API_KEY == 'YOUR_ELEVENLABS_API_KEY_HERE') {
      print('[ElevenLabs] ❌ ERROR: API key not set!');
      print('[ElevenLabs] 🔑 Get FREE key: https://elevenlabs.io/sign-up');
      print('[ElevenLabs] 📝 Then paste it in: lib/core/services/elevenlabs_tts_service.dart line 18');
      return;
    }
    
    // Clean text: Remove markdown formatting and prefixes for natural speech
    String cleanText = text
        .replaceAll('*', '')  // Remove asterisks
        .replaceAll('_', '')  // Remove underscores
        .replaceAll('#', '')  // Remove hashtags
        .replaceAll('[', '')  // Remove brackets
        .replaceAll(']', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll(RegExp(r'^AI:\s*', caseSensitive: false), '')  // Remove "AI:" prefix
        .replaceAll(RegExp(r'^User:\s*', caseSensitive: false), '')  // Remove "User:" prefix
        .trim();
    
    try {
      _isSpeaking = true;
      print('[ElevenLabs] 🎤 Generating speech for: ${cleanText.substring(0, cleanText.length > 50 ? 50 : cleanText.length)}...');
      print('[ElevenLabs] 🔑 Using API key: ${API_KEY.substring(0, 10)}...');
      print('[ElevenLabs] 🎙️ Using voice: $DEFAULT_VOICE');
      
      // Request audio from ElevenLabs API (v1)
      final url = 'https://api.elevenlabs.io/v1/text-to-speech/$DEFAULT_VOICE';
      print('[ElevenLabs] 📡 Calling: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'xi-api-key': API_KEY,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': cleanText,
          'model_id': 'eleven_multilingual_v2',  // Updated to v2 model
          'output_format': 'mp3_44100_128',      // Required format parameter
          'voice_settings': {
            'stability': 0.70,
            'similarity_boost': 0.80,
          }
        }),
      );
      
      print('[ElevenLabs] 📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('[ElevenLabs] ✅ Audio received, playing...');
        
        // Save audio to temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/elevenlabs_audio.mp3');
        await tempFile.writeAsBytes(response.bodyBytes);
        
        // Play audio
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        
        // Wait for completion
        await _audioPlayer.onPlayerComplete.first;
        
        print('[ElevenLabs] ✅ Speech completed');
        
      } else if (response.statusCode == 401) {
        print('[ElevenLabs] ❌ ERROR 401: Invalid API key');
        print('[ElevenLabs] � Response: ${response.body}');
        print('[ElevenLabs] 💡 Possible fixes:');
        print('[ElevenLabs]    1. Wait 1-2 minutes for new key to activate');
        print('[ElevenLabs]    2. Verify key at: https://elevenlabs.io/app/settings/api-keys');
        print('[ElevenLabs]    3. Make sure you copied the FULL key (starts with sk_)');
        print('[ElevenLabs]    4. Check if key has proper permissions');
      } else if (response.statusCode == 429) {
        print('[ElevenLabs] ❌ ERROR 429: Monthly quota exceeded (10k chars)');
        print('[ElevenLabs] 💎 Upgrade: https://elevenlabs.io/pricing');
      } else {
        print('[ElevenLabs] ❌ ERROR ${response.statusCode}');
        print('[ElevenLabs] 📄 Response body: ${response.body}');
        print('[ElevenLabs] 🔍 Headers sent: xi-api-key=${API_KEY.substring(0, 10)}...');
      }
      
    } catch (e) {
      print('[ElevenLabs] ❌ Error: $e');
    } finally {
      _isSpeaking = false;
    }
  }
  
  /// Stop speaking
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      print('[ElevenLabs] Speech stopped');
    } catch (e) {
      print('[ElevenLabs] Error stopping: $e');
      _isSpeaking = false;
    }
  }
  
  /// Change voice (optional - call before speak())
  /// Available voices: VOICE_ADAM, VOICE_ANTONI, VOICE_ARNOLD, VOICE_BELLA
  String currentVoice = DEFAULT_VOICE;
  
  void setVoice(String voiceId) {
    currentVoice = voiceId;
    print('[ElevenLabs] Voice changed to: $voiceId');
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
      _isSpeaking = false;
      print('[ElevenLabs] Disposed');
    } catch (e) {
      print('[ElevenLabs] Error during disposal: $e');
    }
  }
}
