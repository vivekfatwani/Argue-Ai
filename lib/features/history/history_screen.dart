import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/debate_provider.dart';
import '../../core/models/debate_model.dart';
import '../../core/utils.dart';
import '../../core/constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Debate> _debates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebateHistory();
  }

  Future<void> _loadDebateHistory() async {
    setState(() {
      _isLoading = true;
    });

    final debateProvider = Provider.of<DebateProvider>(context, listen: false);
    final debates = await debateProvider.getDebateHistory();
    
    // Sort debates by start time (newest first)
    debates.sort((a, b) => b.startTime.compareTo(a.startTime));

    if (mounted) {
      setState(() {
        _debates = debates;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debate History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debates.isEmpty
              ? _buildEmptyState()
              : _buildDebateList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No debate history yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a debate to see your history here',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppConstants.routeDashboard),
            child: const Text('Start a Debate'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebateList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _debates.length,
      itemBuilder: (context, index) {
        final debate = _debates[index];
        return _buildDebateCard(debate);
      },
    );
  }

  Widget _buildDebateCard(Debate debate) {
    final formattedDate = Utils.formatDate(debate.startTime);
    final duration = debate.duration;
    final durationText = duration.inMinutes > 0
        ? '${duration.inMinutes} min'
        : '${duration.inSeconds} sec';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          if (debate.isCompleted) {
            context.go(AppConstants.routeFeedback, extra: debate.id);
          } else {
            // For incomplete debates, we could offer to resume them
            // For now, just show feedback if available
            if (debate.feedback != null) {
              context.go(AppConstants.routeFeedback, extra: debate.id);
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    debate.mode == DebateMode.text ? Icons.chat : Icons.mic,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    debate.mode == DebateMode.text ? 'Text Debate' : 'Voice Debate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                debate.topic,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    '${debate.messageCount} messages',
                    Icons.message,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    durationText,
                    Icons.timer,
                  ),
                  const Spacer(),
                  if (debate.isCompleted)
                    _buildScoreBadge(debate.feedback),
                ],
              ),
              if (debate.isCompleted && debate.feedback != null)
                _buildSkillBars(debate.feedback!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(Map<String, double>? feedback) {
    if (feedback == null) return const SizedBox.shrink();
    
    // Calculate average score
    double totalScore = 0;
    feedback.forEach((_, value) => totalScore += value);
    final averageScore = totalScore / feedback.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getScoreColor(averageScore),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${(averageScore * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSkillBars(Map<String, double> feedback) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: feedback.entries.map((entry) {
          final skill = entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1);
          final value = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    skill,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.grey[300],
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: _getScoreColor(value),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightGreen;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
