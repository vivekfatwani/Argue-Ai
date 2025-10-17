import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';

class DebateTopicSelector extends StatefulWidget {
  final String mode;

  const DebateTopicSelector({
    Key? key,
    required this.mode,
  }) : super(key: key);

  @override
  State<DebateTopicSelector> createState() => _DebateTopicSelectorState();
}

class _DebateTopicSelectorState extends State<DebateTopicSelector> {
  final TextEditingController _customTopicController = TextEditingController();
  String? _selectedTopic;
  bool _isCustomTopic = false;

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  void _startDebate() {
    final topic = _isCustomTopic ? _customTopicController.text : _selectedTopic;
    
    if (topic == null || topic.isEmpty) {
      Utils.showSnackBar(
        context,
        'Please select a topic or enter a custom one',
        isError: true,
      );
      return;
    }

    if (widget.mode == 'text') {
      context.go(AppConstants.routeTextDebate, extra: topic);
    } else {
      context.go(AppConstants.routeVoiceDebate, extra: topic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.0,
        right: 16.0,
        top: 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select a Debate Topic',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Predefined topics
          if (!_isCustomTopic) ...[
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppConstants.debateTopics.length,
                itemBuilder: (context, index) {
                  final topic = AppConstants.debateTopics[index];
                  return RadioListTile<String>(
                    title: Text(topic),
                    value: topic,
                    groupValue: _selectedTopic,
                    onChanged: (value) {
                      setState(() {
                        _selectedTopic = value;
                      });
                    },
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isCustomTopic = true;
                  _selectedTopic = null;
                });
              },
              child: const Text('Enter a custom topic'),
            ),
          ],
          
          // Custom topic input
          if (_isCustomTopic) ...[
            TextField(
              controller: _customTopicController,
              decoration: const InputDecoration(
                labelText: 'Enter your debate topic',
                hintText: 'e.g., Should space exploration be privatized?',
              ),
              maxLines: 2,
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isCustomTopic = false;
                  _customTopicController.clear();
                });
              },
              child: const Text('Choose from predefined topics'),
            ),
          ],
          
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startDebate,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Start ${widget.mode == 'text' ? 'Text' : 'Voice'} Debate'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
