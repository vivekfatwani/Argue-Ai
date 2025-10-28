import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class AudioService {
  // Speech to text (mock implementation)
  bool _isListening = false;
  String _lastWords = '';
  final StreamController<String> _speechResultsController = StreamController<String>.broadcast();
  Stream<String> get speechResults => _speechResultsController.stream;
  // Real speech-to-text engine (optional)
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _hasSpeech = false;
  Timer? _mockTimer;
  
  // Text to speech (real implementation)
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  final StreamController<TtsState> _ttsStateController = StreamController<TtsState>.broadcast();
  Stream<TtsState> get ttsState => _ttsStateController.stream;
  bool _hasTts = false;
  
  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  
  // Initialize the audio service
  Future<void> init() async {
    // Initialize audio player
    _audioPlayer.onPlayerComplete.listen((_) {
      _isSpeaking = false;
      _ttsState = TtsState.stopped;
      _ttsStateController.add(_ttsState);
    });

    // Initialize Flutter TTS
    try {
      // Set up TTS completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _ttsState = TtsState.stopped;
        _ttsStateController.add(_ttsState);
        print('[AudioService] TTS completed');
      });

      // Set up TTS error handler
      _flutterTts.setErrorHandler((message) {
        _isSpeaking = false;
        _ttsState = TtsState.stopped;
        _ttsStateController.add(_ttsState);
        print('[AudioService] TTS error: $message');
      });

      // Configure default TTS settings for natural, debate-style speech
      await _flutterTts.setLanguage("en-US");
      
      // PACE CONTROL: Using combination of speech rate + extensive pauses
      // Speech rate: 0.4 (moderate) combined with many pauses = natural debate pace
      await _flutterTts.setSpeechRate(0.4);
      
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(0.90); // Slightly lower pitch for more natural sound
      
      // Try to set a more natural voice if available
      try {
        final voices = await _flutterTts.getVoices;
        if (voices != null && voices is List && voices.isNotEmpty) {
          // Try to find a good quality voice (prefer neural/enhanced voices)
          for (var voice in voices) {
            final voiceMap = voice as Map<dynamic, dynamic>;
            final name = voiceMap['name']?.toString().toLowerCase() ?? '';
            
            // Prefer voices with "enhanced", "neural", or natural-sounding names
            if (name.contains('enhanced') || 
                name.contains('neural') ||
                name.contains('quality')) {
              // Convert to proper type
              final voiceConfig = <String, String>{};
              voiceMap.forEach((key, value) {
                if (key != null && value != null) {
                  voiceConfig[key.toString()] = value.toString();
                }
              });
              await _flutterTts.setVoice(voiceConfig);
              print('[AudioService] Using enhanced voice: $name');
              break;
            }
          }
        }
      } catch (e) {
        print('[AudioService] Could not set custom voice: $e');
      }
      
      _hasTts = true;
      print('[AudioService] TTS initialized successfully');
    } catch (e) {
      _hasTts = false;
      print('[AudioService] Failed to init TTS: $e');
    }

    // Try to initialize the real STT engine; if it fails, we'll fall back to mock
    try {
      _hasSpeech = await _speechToText.initialize(
        onError: (err) {
          // initialization errors are non-fatal; keep mock fallback
          print('[AudioService] STT init error: $err');
        },
        onStatus: (status) {
          // status updates are optional
        },
      );
      print('[AudioService] STT available: $_hasSpeech');
    } catch (e) {
      _hasSpeech = false;
      print('[AudioService] Failed to init STT: $e');
    }
  }
  
  // Start listening for speech (mock implementation)
  Future<void> startListening() async {
    if (!_isListening) {
      _isListening = true;
      
      // If real STT is available, start listening using the plugin
      if (_hasSpeech) {
        try {
          await _speechToText.listen(
            onResult: (result) {
              if (!_isListening) return;
              // Use dynamic access to avoid a hard dependency on the concrete type name
              final recognized = (result as dynamic).recognizedWords as String? ?? '';
              _lastWords = recognized;
              try {
                print('[AudioService] STT result: $_lastWords');
              } catch (_) {}
              _speechResultsController.add(_lastWords);
            },
            listenMode: stt.ListenMode.confirmation,
            partialResults: true,
          );
        } catch (e) {
          print('[AudioService] Error starting STT listen: $e');
          _hasSpeech = false;
        }
      }

      // If STT is not available or failed to start, keep the mock fallback
      if (!_hasSpeech) {
        _mockTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (!_isListening) {
            timer.cancel();
            return;
          }

          // Simulate partial results
          _lastWords = 'Simulated speech input...';
          // Debug log the simulated speech so callers can see what's happening
          try {
            // Use print here to ensure logs appear in debug console
            print('[AudioService] Simulated speech result: $_lastWords');
          } catch (_) {}
          _speechResultsController.add(_lastWords);
        });
      }
    }
  }
  
  // Stop listening for speech
  Future<void> stopListening() async {
    _isListening = false;
    // Stop real STT if active
    try {
      if (_hasSpeech && _speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      print('[AudioService] Error stopping STT: $e');
    }

    // Cancel mock timer if present
    try {
      _mockTimer?.cancel();
      _mockTimer = null;
    } catch (_) {}

    return;
  }
  
  // Get the last recognized words and clear them
  String getLastWords() {
    final words = _lastWords;
    _lastWords = ''; // Clear after retrieval to prevent duplicate submissions
    return words;
  }
  
  // Speak text (real implementation with fallback)
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Stop any ongoing speech first
    if (_isSpeaking) {
      await stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    _isSpeaking = true;
    _ttsState = TtsState.playing;
    _ttsStateController.add(_ttsState);
    
    try {
      if (_hasTts) {
        // Add pauses to the full text for natural pacing
        String processedText = _addNaturalPauses(text);
        
        print('[AudioService] Speaking with TTS (debate mode): ${processedText.substring(0, processedText.length > 50 ? 50 : processedText.length)}...');
        
        // Speak the full text at once (let completion handler manage the end)
        await _flutterTts.speak(processedText);
        
        // The completion handler will automatically set _isSpeaking = false
        // when the TTS engine finishes speaking
      } else {
        // Fallback to mock implementation
        print('[AudioService] Using mock TTS (no real TTS available)');
        final duration = Duration(milliseconds: text.length * 50);
        await Future.delayed(duration);
        
        _isSpeaking = false;
        _ttsState = TtsState.stopped;
        _ttsStateController.add(_ttsState);
      }
    } catch (e) {
      print('[AudioService] Error speaking: $e');
      _isSpeaking = false;
      _ttsState = TtsState.stopped;
      _ttsStateController.add(_ttsState);
    }
  }
  
  // Split text into smaller chunks for controlled pacing
  List<String> _splitIntoChunks(String text) {
    List<String> chunks = [];
    
    // Split by sentences first
    List<String> sentences = text.split(RegExp(r'[.!?]+'));
    
    for (String sentence in sentences) {
      sentence = sentence.trim();
      if (sentence.isEmpty) continue;
      
      // If sentence is short, use it as is
      if (sentence.split(' ').length <= 8) {
        chunks.add(sentence);
      } else {
        // Split long sentences by commas or conjunctions
        List<String> parts = sentence.split(RegExp(r',|\sand\s|\sbut\s|\sor\s'));
        for (String part in parts) {
          part = part.trim();
          if (part.isNotEmpty) {
            chunks.add(part);
          }
        }
      }
    }
    
    return chunks;
  }
  
  // Add natural pauses to text for debate-style speech
  String _addNaturalPauses(String text) {
    // Add extensive pauses to slow down the speech
    String result = text;
    
    // Very long pause after sentences (period, exclamation, question)
    result = result.replaceAll('. ', '.......... ');  // 10 dots for long pause
    result = result.replaceAll('! ', '.......... ');
    result = result.replaceAll('? ', '.......... ');
    
    // Medium pause after commas and semicolons
    result = result.replaceAll(', ', ',,,,, ');  // 5 commas for medium pause
    result = result.replaceAll('; ', ';;;;; ');
    
    // Small pause after conjunctions
    result = result.replaceAll(' and ', ',, and ');
    result = result.replaceAll(' but ', ',, but ');
    result = result.replaceAll(' or ', ',, or ');
    result = result.replaceAll(' because ', ',,,, because ');
    result = result.replaceAll(' however ', ',,,,, however ');
    result = result.replaceAll(' therefore ', ',,,,, therefore ');
    
    return result;
  }
  
  // Stop speaking
  Future<void> stop() async {
    if (_isSpeaking) {
      try {
        if (_hasTts) {
          await _flutterTts.stop();
        }
      } catch (e) {
        print('[AudioService] Error stopping TTS: $e');
      }
      _isSpeaking = false;
      _ttsState = TtsState.stopped;
      _ttsStateController.add(_ttsState);
    }
  }
  
  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    try {
      if (_hasTts) {
        await _flutterTts.setSpeechRate(rate);
      }
    } catch (e) {
      print('[AudioService] Error setting speech rate: $e');
    }
  }
  
  // Set pitch
  Future<void> setPitch(double pitch) async {
    try {
      if (_hasTts) {
        await _flutterTts.setPitch(pitch);
      }
    } catch (e) {
      print('[AudioService] Error setting pitch: $e');
    }
  }
  
  // Play a sound effect
  Future<void> playSound(String soundType) async {
    try {
      // Play different sounds based on type
      String assetPath = 'assets/sounds/notification.mp3';
      
      if (soundType == 'success') {
        assetPath = 'assets/sounds/success.mp3';
      } else if (soundType == 'error') {
        assetPath = 'assets/sounds/error.mp3';
      }
      
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }
  
  // Dispose resources
  void dispose() {
    _speechResultsController.close();
    _ttsStateController.close();
    _audioPlayer.dispose();
    try {
      _mockTimer?.cancel();
    } catch (_) {}
  }
}
