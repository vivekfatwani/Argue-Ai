import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class AudioProvider with ChangeNotifier {
  final AudioService _audioService;
  final StorageService _storageService;
  
  bool _isInitialized = false;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  
  AudioProvider(this._audioService, this._storageService) {
    _initialize();
  }
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _audioService.isListening;
  bool get isSpeaking => _audioService.isSpeaking;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  Stream<String> get speechResults => _audioService.speechResults;
  Stream<TtsState> get ttsState => _audioService.ttsState;
  
  // Initialize the audio service and load preferences
  Future<void> _initialize() async {
    await _audioService.init();
    
    final preferences = await _storageService.getUserPreferences();
    _speechRate = preferences['voiceSpeed'] ?? 1.0;
    _pitch = preferences['voicePitch'] ?? 1.0;
    
    await _audioService.setSpeechRate(_speechRate);
    await _audioService.setPitch(_pitch);
    
    _isInitialized = true;
    notifyListeners();
  }
  
  // Start speech recognition
  Future<void> startListening() async {
    if (_isInitialized) {
      await _audioService.startListening();
      notifyListeners();
    }
  }
  
  // Stop speech recognition
  Future<void> stopListening() async {
    if (_isInitialized) {
      await _audioService.stopListening();
      notifyListeners();
    }
  }
  
  // Get the last recognized words
  String getLastWords() {
    return _audioService.getLastWords();
  }
  
  // Speak text
  Future<void> speak(String text) async {
    if (_isInitialized) {
      await _audioService.speak(text);
      notifyListeners();
    }
  }
  
  // Stop speaking
  Future<void> stopSpeaking() async {
    if (_isInitialized) {
      await _audioService.stop();
      notifyListeners();
    }
  }
  
  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    if (_isInitialized) {
      _speechRate = rate;
      await _audioService.setSpeechRate(rate);
      
      final preferences = await _storageService.getUserPreferences();
      preferences['voiceSpeed'] = rate;
      await _storageService.saveUserPreferences(preferences);
      
      notifyListeners();
    }
  }
  
  // Set speech pitch
  Future<void> setPitch(double pitch) async {
    if (_isInitialized) {
      _pitch = pitch;
      await _audioService.setPitch(pitch);
      
      final preferences = await _storageService.getUserPreferences();
      preferences['voicePitch'] = pitch;
      await _storageService.saveUserPreferences(preferences);
      
      notifyListeners();
    }
  }
  
  // Play a sound effect
  Future<void> playSound(String soundType) async {
    if (_isInitialized) {
      await _audioService.playSound(soundType);
    }
  }
  
  // Dispose resources
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
