import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

enum TtsState { playing, stopped, paused, continued }

class AudioService {
  // Speech to text (mock implementation)
  bool _isListening = false;
  String _lastWords = '';
  final StreamController<String> _speechResultsController = StreamController<String>.broadcast();
  Stream<String> get speechResults => _speechResultsController.stream;
  
  // Text to speech (mock implementation)
  TtsState _ttsState = TtsState.stopped;
  final StreamController<TtsState> _ttsStateController = StreamController<TtsState>.broadcast();
  Stream<TtsState> get ttsState => _ttsStateController.stream;
  
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
  }
  
  // Start listening for speech (mock implementation)
  Future<void> startListening() async {
    if (!_isListening) {
      _isListening = true;
      
      // Simulate speech recognition with a timer
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
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
  
  // Stop listening for speech
  Future<void> stopListening() async {
    _isListening = false;
    return;
  }
  
  // Get the last recognized words
  String getLastWords() {
    return _lastWords;
  }
  
  // Speak text (mock implementation)
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    _isSpeaking = true;
    _ttsState = TtsState.playing;
    _ttsStateController.add(_ttsState);
    
    // Simulate TTS with a delay based on text length
    final duration = Duration(milliseconds: text.length * 50);
    await Future.delayed(duration);
    
    _isSpeaking = false;
    _ttsState = TtsState.stopped;
    _ttsStateController.add(_ttsState);
  }
  
  // Stop speaking
  Future<void> stop() async {
    if (_isSpeaking) {
      _isSpeaking = false;
      _ttsState = TtsState.stopped;
      _ttsStateController.add(_ttsState);
    }
  }
  
  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    // Mock implementation
    return;
  }
  
  // Set pitch
  Future<void> setPitch(double pitch) async {
    // Mock implementation
    return;
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
  }
}
