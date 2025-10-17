import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/providers/debate_provider.dart';
import '../../core/models/debate_model.dart';
import '../../widgets/debate_bubble.dart';
import '../../widgets/typing_indicator.dart';

class TextDebateScreen extends StatefulWidget {
  final String topic;

  const TextDebateScreen({
    Key? key,
    required this.topic,
  }) : super(key: key);

  @override
  State<TextDebateScreen> createState() => _TextDebateScreenState();
}

class _TextDebateScreenState extends State<TextDebateScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDebate();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startDebate() async {
    final debateProvider = Provider.of<DebateProvider>(context, listen: false);
    await debateProvider.startDebate(widget.topic, DebateMode.text);
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;
    
    _messageController.clear();
    setState(() {
      _isComposing = false;
    });

    final debateProvider = Provider.of<DebateProvider>(context, listen: false);
    debateProvider.addUserMessage(text);
    
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
        title: Text('Debate: ${widget.topic}'),
        actions: [
          TextButton(
            onPressed: _endDebate,
            child: const Text('End Debate'),
          ),
        ],
      ),
      body: Consumer<DebateProvider>(
        builder: (context, debateProvider, child) {
          final debate = debateProvider.currentDebate;
          final isLoading = debateProvider.isLoading;
          final isAiTyping = debateProvider.isAiTyping;
          
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
              
              // Message input
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onChanged: (text) {
                            setState(() {
                              _isComposing = text.isNotEmpty;
                            });
                          },
                          onSubmitted: _isComposing ? _handleSubmitted : null,
                          decoration: const InputDecoration(
                            hintText: 'Type your argument...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_messageController.text)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
