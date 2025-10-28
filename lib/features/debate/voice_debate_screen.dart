import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/providers/debate_provider.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/models/debate_model.dart';
import '../../widgets/debate_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/voice_wave.dart';
import '../../core/services/elevenlabs_tts_service.dart';

class VoiceDebateScreen extends StatefulWidget {
  final String topic;

  const VoiceDebateScreen({
    Key? key,
    required this.topic,
  }) : super(key: key);

  @override
  State<VoiceDebateScreen> createState() => _VoiceDebateScreenState();
}

class _VoiceDebateScreenState extends State<VoiceDebateScreen> {
  final ScrollController _scrollController = ScrollController();
  final ElevenLabsTTS _elevenLabsTTS = ElevenLabsTTS(); // ElevenLabs TTS service
  bool _isListening = false;
  String _currentSpeech = '';
  int _lastMessageCount = 0; // Track message count to detect new AI responses

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDebate();
      _setupSpeechListener();
    });
  }

  @override
  void dispose() {
    // Stop any ongoing speech before disposing
    _elevenLabsTTS.stop();
    _elevenLabsTTS.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startDebate() async {
    final debateProvider = Provider.of<DebateProvider>(context, listen: false);
    await debateProvider.startDebate(widget.topic, DebateMode.voice);
    
    // Initialize message count after debate starts
    if (mounted) {
      setState(() {
        _lastMessageCount = debateProvider.currentDebate?.messages.length ?? 0;
      });
      
      // Speak the initial AI message using ElevenLabs
      if (debateProvider.currentDebate != null && 
          debateProvider.currentDebate!.messages.isNotEmpty) {
        final lastMessage = debateProvider.currentDebate!.messages.last;
        if (!lastMessage.isUser) {
          await _elevenLabsTTS.speak(lastMessage.content);
          
          // Auto-enable microphone after AI finishes speaking
          if (mounted) {
            _toggleListening();
          }
        }
      }
    }
  }

  void _setupSpeechListener() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    
    audioProvider.speechResults.listen((result) {
      // Guard against calling setState after dispose
      if (!mounted) return;
      // Debug log for recognized speech
      // Use developer.log to keep logs consistent with other services
      try {
        // developer.log may not be imported here, use debugPrint as safe alternative
        debugPrint('[VoiceDebateScreen] Speech recognized: $result');
      } catch (_) {}

      setState(() {
        _currentSpeech = result;
      });
    });
  }

  void _toggleListening() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    
    if (_isListening) {
      await audioProvider.stopListening();
      
      // Submit the recognized speech if valid
      final speech = audioProvider.getLastWords().trim();
      
      // Filter out invalid/incomplete speech
      bool isValidSpeech = speech.isNotEmpty && 
                          speech != 'Simulated speech input...' &&
                          speech.length > 5 &&  // At least 6 characters
                          speech.split(' ').length >= 3;  // At least 3 words
      
      if (isValidSpeech) {
        try {
          debugPrint('[VoiceDebateScreen] Submitting recognized speech: $speech');
        } catch (_) {}

        final debateProvider = Provider.of<DebateProvider>(context, listen: false);
        debateProvider.addUserMessage(speech);

        // Clear the current speech display
        if (mounted) {
          setState(() {
            _currentSpeech = '';
          });
        }

        // Scroll to bottom after message is added
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        // Incomplete speech - show message and don't submit
        debugPrint('[VoiceDebateScreen] Speech too short, not submitting: "$speech"');
        if (mounted) {
          setState(() {
            _currentSpeech = '';
          });
        }
      }
    } else {
      // Stop AI speaking if user wants to interrupt and speak
      if (audioProvider.isSpeaking) {
        await audioProvider.stopSpeaking();
        debugPrint('[VoiceDebateScreen] User interrupted AI speech');
      }
      
      if (mounted) {
        setState(() {
          _currentSpeech = '';
        });
      }
      await audioProvider.startListening();
    }
    
    if (mounted) {
      setState(() {
        _isListening = !_isListening;
      });
    }
  }

  void _endDebate() async {
    final debateProvider = Provider.of<DebateProvider>(context, listen: false);
    await debateProvider.endDebate();
    
    if (mounted) {
      final debateId = debateProvider.currentDebate?.id ?? '';
      context.go(AppConstants.routeFeedback, extra: debateId);
    }
  }

  // Check for new AI messages and speak them using ElevenLabs
  void _checkAndSpeakNewAiMessage(DebateProvider debateProvider) async {
    if (debateProvider.currentDebate == null) return;
    
    final currentMessageCount = debateProvider.currentDebate!.messages.length;
    
    // If there's a new message
    if (currentMessageCount > _lastMessageCount) {
      _lastMessageCount = currentMessageCount;
      
      // Get the latest message
      final lastMessage = debateProvider.currentDebate!.messages.last;
      
      // If it's from the AI and not typing anymore, speak it
      if (!lastMessage.isUser && !debateProvider.isAiTyping) {
        debugPrint('[VoiceDebateScreen] Speaking AI response: ${lastMessage.content}');
        await _elevenLabsTTS.speak(lastMessage.content);
        
        // Auto-enable microphone after AI finishes speaking
        if (mounted && !_isListening) {
          debugPrint('[VoiceDebateScreen] AI finished speaking, auto-enabling microphone');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isListening) {
              _toggleListening();
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Debate: ${widget.topic}'),
        actions: [
          TextButton(
            onPressed: _endDebate,
            child: const Text('End Debate'),
          ),
        ],
      ),
      body: Consumer2<DebateProvider, AudioProvider>(
        builder: (context, debateProvider, audioProvider, child) {
          final debate = debateProvider.currentDebate;
          final isLoading = debateProvider.isLoading;
          final isAiTyping = debateProvider.isAiTyping;
          final isSpeaking = audioProvider.isSpeaking;
          
          // Check for new AI messages to speak
          if (!isLoading && debate != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAndSpeakNewAiMessage(debateProvider);
            });
          }
          
          if (isLoading || debate == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          return Column(
            children: [
              // Topic card
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Topic:',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          debate.topic,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: debate.messages.length + (isAiTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == debate.messages.length) {
                      // Show typing indicator as the last item when AI is typing
                      return const TypingIndicator();
                    }
                    
                    final message = debate.messages[index];
                    return DebateBubble(
                      message: message.content,
                      isUser: message.isUser,
                      timestamp: message.timestamp,
                    );
                  },
                ),
              ),
              
              // Current speech display
              if (_isListening && _currentSpeech.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Currently speaking:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentSpeech,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Voice controls
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instruction text
                    Text(
                      isSpeaking 
                          ? 'AI is responding... (tap stop to interrupt)'
                          : _isListening 
                              ? 'Listening... Speak at least 3 words, then tap to submit'
                              : 'Tap microphone to speak your argument',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSpeaking)
                          // Stop AI speech button
                          GestureDetector(
                            onTap: () async {
                              await audioProvider.stopSpeaking();
                              debugPrint('[VoiceDebateScreen] User interrupted AI speech');
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.error,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.stop_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          )
                        else
                          // Microphone button
                          GestureDetector(
                            onTap: _toggleListening,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isListening
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isListening 
                                        ? Theme.of(context).colorScheme.error 
                                        : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _isListening ? Icons.stop_rounded : Icons.mic,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Voice wave animation when listening
              if (_isListening)
                SizedBox(
                  height: 40,
                  child: VoiceWave(isActive: true),
                ),
            ],
          );
        },
      ),
    );
  }
}
