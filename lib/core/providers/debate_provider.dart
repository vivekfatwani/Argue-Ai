import 'package:flutter/foundation.dart';
import '../models/debate_model.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../utils.dart';

class DebateProvider with ChangeNotifier {
  final StorageService _storageService;
  final AIService _aiService;

  Debate? _currentDebate;
  bool _isLoading = false;
  bool _isAiTyping = false;

  DebateProvider(this._storageService, this._aiService);

  Debate? get currentDebate => _currentDebate;
  bool get isLoading => _isLoading;
  bool get isAiTyping => _isAiTyping;

  // Start a new debate
  Future<void> startDebate(String topic, DebateMode mode) async {
    _isLoading = true;
    notifyListeners();

    _currentDebate = Debate.create(topic: topic, mode: mode);

    // Add an initial AI message to start the debate (concise for voice mode)
    final initialMessage = mode == DebateMode.voice
        ? "I'll argue against your position on: $topic. You start first."
        : "I'm ready to debate the topic: \"$topic\". Would you like to go first, or should I start?";
    
    await addAiMessage(
      initialMessage,
      speakInVoiceMode: mode == DebateMode.voice,
    );

    _isLoading = false;
    notifyListeners();
  }

  // Add a user message to the debate
  Future<void> addUserMessage(String content) async {
    if (_currentDebate == null) return;

    final message = DebateMessage(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<DebateMessage>.from(_currentDebate!.messages)
      ..add(message);
    _currentDebate = _currentDebate!.copyWith(messages: updatedMessages);

    await _storageService.saveDebate(_currentDebate!);
    notifyListeners();

    // Generate AI response (enable speech for voice mode)
    await generateAiResponse(speakInVoiceMode: _currentDebate!.mode == DebateMode.voice);
  }

  // Add an AI message to the debate
  Future<void> addAiMessage(String content, {bool speakInVoiceMode = false}) async {
    if (_currentDebate == null) return;

    final message = DebateMessage(
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<DebateMessage>.from(_currentDebate!.messages)
      ..add(message);
    _currentDebate = _currentDebate!.copyWith(messages: updatedMessages);

    await _storageService.saveDebate(_currentDebate!);
    notifyListeners();
  }

  // Generate AI response based on the current debate
  Future<void> generateAiResponse({bool speakInVoiceMode = false}) async {
    if (_currentDebate == null) return;

    _isAiTyping = true;
    notifyListeners();

    try {
      final response = await _aiService.generateDebateResponse(
        _currentDebate!.topic,
        _currentDebate!.messages,
      );

      await addAiMessage(response, speakInVoiceMode: speakInVoiceMode);
    } catch (e) {
      await addAiMessage(
        "I'm sorry, I couldn't generate a response at this time. Let's continue the debate.",
        speakInVoiceMode: speakInVoiceMode,
      );
    }

    _isAiTyping = false;
    notifyListeners();
  }

  // End the current debate
  Future<void> endDebate() async {
    if (_currentDebate == null) return;

    _isLoading = true;
    notifyListeners();

    _currentDebate = _currentDebate!.copyWith(endTime: DateTime.now());

    await _storageService.saveDebate(_currentDebate!);

    _isLoading = false;
    notifyListeners();
  }

  // Generate feedback for the current debate
  Future<Map<String, dynamic>> generateFeedback() async {
    if (_currentDebate == null || !_currentDebate!.isCompleted) {
      return {'error': 'No completed debate to analyze'};
    }

    _isLoading = true;
    notifyListeners();

    final feedback = await _aiService.generateDebateFeedback(
      _currentDebate!.topic,
      _currentDebate!.messages,
    );

    // Save feedback to the debate
    if (feedback.containsKey('skillRatings')) {
      final skillRatings = Map<String, double>.from(feedback['skillRatings']);
      _currentDebate = _currentDebate!.copyWith(feedback: skillRatings);
      await _storageService.saveDebate(_currentDebate!);
    }

    _isLoading = false;
    notifyListeners();

    return feedback;
  }

  // Load debate history
  Future<List<Debate>> getDebateHistory() async {
    return await _storageService.getDebateHistory();
  }

  // Load a specific debate from history
  Future<void> loadDebate(String debateId) async {
    _isLoading = true;
    notifyListeners();

    final history = await _storageService.getDebateHistory();
    _currentDebate = history.firstWhere(
      (debate) => debate.id == debateId,
      orElse:
          () => Debate.create(topic: 'Unknown Topic', mode: DebateMode.text),
    );

    _isLoading = false;
    notifyListeners();
  }

  // Clear the current debate
  void clearCurrentDebate() {
    _currentDebate = null;
    notifyListeners();
  }
}
