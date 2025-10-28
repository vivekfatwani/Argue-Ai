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
/// 2. Get your API key from Settings
/// 3. Paste it below in API_KEY constant
class ElevenLabsTTS {
  // TODO: Add your ElevenLabs API key here
  // Get it from: https://elevenlabs.io/app/settings/api-keys
  static const String API_KEY = 'sk_f290a72500b801529847186d6deaf1be840ba5ac7a74a73e';
  
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
      print('[ElevenLabs] ERROR: API key not set! Get one from https://elevenlabs.io');
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
      print('[ElevenLabs] Generating speech for: ${cleanText.substring(0, cleanText.length > 50 ? 50 : cleanText.length)}...');
      
      // Request audio from ElevenLabs
      final response = await http.post(
        Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$DEFAULT_VOICE'),
        headers: {
          'xi-api-key': API_KEY,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': cleanText,  // Use cleaned text without markdown
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.70,           // More natural variation (0-1)
            'similarity_boost': 0.80,    // More human-like (0-1)
            'style': 0.30,               // Slight expressiveness for debate
            'use_speaker_boost': true,   // Enhance clarity
          }
        }),
      );
      
      if (response.statusCode == 200) {
        print('[ElevenLabs] Audio received, playing...');
        
        // Save audio to temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/elevenlabs_audio.mp3');
        await tempFile.writeAsBytes(response.bodyBytes);
        
        // Play audio
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        
        // Wait for completion
        await _audioPlayer.onPlayerComplete.first;
        
        print('[ElevenLabs] Speech completed');
        
      } else if (response.statusCode == 401) {
        print('[ElevenLabs] ERROR: Invalid API key. Check your key at https://elevenlabs.io/app/settings/api-keys');
      } else if (response.statusCode == 429) {
        print('[ElevenLabs] ERROR: Monthly quota exceeded (10k chars). Upgrade at https://elevenlabs.io/pricing');
      } else {
        print('[ElevenLabs] Error: ${response.statusCode} - ${response.body}');
      }
      
    } catch (e) {
      print('[ElevenLabs] Error: $e');
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
