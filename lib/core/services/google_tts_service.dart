import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

/// Google Cloud Text-to-Speech Service
/// Provides high-quality neural voices with proper pacing
/// 
/// Setup:
/// 1. Create Google Cloud project: https://console.cloud.google.com
/// 2. Enable Text-to-Speech API
/// 3. Create API key
/// 4. Add to your project: const String GOOGLE_TTS_API_KEY = 'your-key-here';
class GoogleTTSService {
  static const String API_KEY = 'YOUR_GOOGLE_CLOUD_API_KEY'; // ← Add your key here
  static const String API_URL = 'https://texttospeech.googleapis.com/v1/text:synthesize';
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  
  bool get isSpeaking => _isSpeaking;
  
  /// Speak text using Google Cloud TTS with debate persona
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    try {
      _isSpeaking = true;
      
      // Build SSML with proper pacing for debate
      String ssml = _buildDebateSSML(text);
      
      // Request audio from Google Cloud TTS
      final response = await http.post(
        Uri.parse('$API_URL?key=$API_KEY'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'input': {'ssml': ssml},
          'voice': {
            'languageCode': 'en-US',
            'name': 'en-US-Neural2-J', // Professional male voice (debate-style)
            // Other options:
            // 'en-US-Neural2-F' - Professional female voice
            // 'en-US-Neural2-A' - Authoritative male voice
            // 'en-US-Studio-O' - Natural conversational male
          },
          'audioConfig': {
            'audioEncoding': 'MP3',
            'speakingRate': 0.85, // Slightly slower for clarity
            'pitch': -2.0, // Lower pitch for authority
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final audioContent = jsonResponse['audioContent'];
        
        // Decode base64 audio
        final audioBytes = base64Decode(audioContent);
        
        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/tts_audio.mp3');
        await tempFile.writeAsBytes(audioBytes);
        
        // Play audio
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        
        // Wait for completion
        await _audioPlayer.onPlayerComplete.first;
        
      } else {
        print('Google TTS Error: ${response.statusCode} - ${response.body}');
      }
      
    } catch (e) {
      print('Error with Google TTS: $e');
    } finally {
      _isSpeaking = false;
    }
  }
  
  /// Build SSML with debate-appropriate pacing and emphasis
  String _buildDebateSSML(String text) {
    // Add SSML tags for natural debate pacing
    String ssml = '<speak>';
    
    // Split into sentences
    List<String> sentences = text.split(RegExp(r'[.!?]+'));
    
    for (int i = 0; i < sentences.length; i++) {
      String sentence = sentences[i].trim();
      if (sentence.isEmpty) continue;
      
      // Add sentence with emphasis and pauses
      ssml += '<prosody rate="slow" pitch="-2st">';
      ssml += sentence;
      ssml += '</prosody>';
      
      // Add pause after sentence (longer for debate)
      if (i < sentences.length - 1) {
        ssml += '<break time="800ms"/>';
      }
    }
    
    ssml += '</speak>';
    return ssml;
  }
  
  /// Stop speaking
  Future<void> stop() async {
    await _audioPlayer.stop();
    _isSpeaking = false;
  }
  
  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
