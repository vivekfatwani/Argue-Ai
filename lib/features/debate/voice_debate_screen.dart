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
  bool _isListening = false;
  String _currentSpeech = '';

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
    _scrollController.dispose();
    super.dispose();
  }

  void _startDebate() async {
    final debateProvider = Provider.of<DebateProvider>(context, listen: false);
    await debateProvider.startDebate(widget.topic, DebateMode.voice);
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
      
      // Submit the recognized speech if not empty
      final speech = audioProvider.getLastWords();
      if (speech.isNotEmpty) {
        try {
          debugPrint('[VoiceDebateScreen] Submitting recognized speech: $speech');
        } catch (_) {}

        final debateProvider = Provider.of<DebateProvider>(context, listen: false);
        debateProvider.addUserMessage(speech);

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
      }
    } else {
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
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSpeaking)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('AI is speaking...'),
                      )
                    else
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
                          ),
                          child: Center(
                            child: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
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
