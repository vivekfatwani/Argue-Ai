import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/debate_provider.dart';
import '../../core/providers/feedback_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/audio_provider.dart';
import '../../core/models/debate_model.dart';
import '../../core/models/feedback_model.dart';
import '../../core/models/user_model.dart';
import '../../core/utils.dart';
import '../../core/utils/animated_widgets.dart';
import '../debate/debate_topic_selector.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomeTab(),
    const HistoryTab(),
    const RoadmapTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ArgueAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notification functionality would go here
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Roadmap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload activity when dependencies change (like when returning to this tab)
    _loadRecentActivity();
  }

  void _loadRecentActivity() {
    final debateProvider = Provider.of<DebateProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);
    
    // Get recent debates
    debateProvider.getDebateHistory().then((debates) {
      // Sort debates by startTime
      debates.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      final activities = <Map<String, dynamic>>[];
      
      // Add recent debates
      for (var i = 0; i < min(2, debates.length); i++) {
        activities.add({
          'type': 'debate',
          'icon': Icons.chat,
          'title': 'Completed a debate on "${debates[i].topic}"',
          'date': debates[i].startTime,
          'id': debates[i].id,
        });
      }
      
      // Add completed resources if available
      if (userProvider.user != null && userProvider.user!.completedResources.isNotEmpty) {
        final completedResources = userProvider.user!.completedResources;
        activities.add({
          'type': 'resource',
          'icon': Icons.book,
          'title': 'Completed ${completedResources.length} learning resource${completedResources.length > 1 ? 's' : ''}',
          'date': DateTime.now().subtract(const Duration(days: 3)), // Approximate date
          'id': '',
        });
      }
      
      // Sort all activities by date
      activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      // Take only the most recent 3 activities
      final recentActivities = activities.take(3).toList();
      
      if (mounted) {
        setState(() {
          _recentActivities = recentActivities;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.name ?? 'Debater'}!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ready to improve your debate skills today?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Debate modes section
          Text(
            'Choose Your Debate Mode',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDebateCard(
                  context,
                  'Text Debate',
                  Icons.chat_bubble_outline,
                  'Debate through text messages',
                  () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => const DebateTopicSelector(mode: 'text'),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDebateCard(
                  context,
                  'Voice Debate',
                  Icons.mic_none,
                  'Debate using your voice',
                  () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => const DebateTopicSelector(mode: 'voice'),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Skills section
          Text(
            'Your Debate Skills',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildSkillsCard(context, user?.skills),
          const SizedBox(height: 24),
          
          // Recent activity section
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _buildRecentActivityCard(context),
        ],
      ),
    );
  }

  Widget _buildDebateCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    final bool isTextDebate = title.contains('Text');
    final Color cardColor = isTextDebate 
        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
        : Theme.of(context).colorScheme.secondary.withOpacity(0.1);
        
    final Color iconColor = isTextDebate
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    
    // Adjust description for text debate to be more compact
    final String displayDescription = isTextDebate ? 'Text-based debates' : description;
        
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 165,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: iconColor,
                ),
              ),
              // Use different spacing based on debate type
              SizedBox(height: isTextDebate ? 10 : 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isTextDebate ? 18 : 20, // Smaller font for Text Debate
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isTextDebate ? 4 : 6), // Less spacing for Text Debate
              Text(
                displayDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 13, // Slightly smaller text to avoid overflow
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsCard(BuildContext context, Map<String, double>? skills) {
    final defaultSkills = {
      'Clarity': 0.0,
      'Logic': 0.0,
      'Rebuttal Quality': 0.0,
      'Persuasiveness': 0.0,
    };
    
    final userSkills = skills?.map(
      (key, value) => MapEntry(key.substring(0, 1).toUpperCase() + key.substring(1), value),
    ) ?? defaultSkills;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...userSkills.entries.map((entry) => _buildSkillBar(
              context,
              entry.key,
              entry.value,
            )),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Access the parent DashboardScreen state to change the tab
                  final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
                  if (dashboardState != null) {
                    dashboardState._onItemTapped(2); // Index 2 is the Roadmap tab
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('View Your Learning Roadmap'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBar(BuildContext context, String skill, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skill),
              Text('${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  // Helper method to format time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    if (_recentActivities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Animated empty state icon
              AnimatedWidgets.pulseAnimation(
                duration: const Duration(milliseconds: 2000),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Animated text
              AnimatedWidgets.fadeInFromBottom(
                index: 0,
                child: Text(
                  'No recent activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedWidgets.fadeInFromBottom(
                index: 1,
                child: Text(
                  'Start a debate to see your activity here',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Animated button
              AnimatedWidgets.fadeInFromBottom(
                index: 2,
                child: AnimatedWidgets.rippleButton(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => const DebateTopicSelector(mode: 'text'),
                    );
                  },
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Start a Debate',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Column(
        children: [
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activity = _recentActivities[index];
              final DateTime activityDate = activity['date'] as DateTime;
              final String timeAgo = _getTimeAgo(activityDate);
              
              // Use our animated widgets for a more engaging experience
              return AnimatedWidgets.fadeInFromBottom(
                index: index,
                child: AnimatedWidgets.animatedCard(
                  onTap: () {
                    // Navigate based on activity type
                    if (activity['type'] == 'debate' && activity['id'] != null) {
                      context.go(
                        AppConstants.routeFeedback,
                        extra: activity['id'],
                      );
                    } else if (activity['type'] == 'resource') {
                      context.go(AppConstants.routeRoadmap);
                    }
                  },
                  color: Theme.of(context).cardColor,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          activity['icon'] as IconData,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeAgo,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedWidgets.rippleButton(
              onTap: () {
                // Show a loading indicator while refreshing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing activity...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                _loadRecentActivity(); // Refresh the activity list
              },
              splashColor: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedWidgets.pulseAnimation(
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Refresh Activity',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryTab extends StatefulWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _debates.isEmpty
            ? _buildEmptyState()
            : _buildDebateList();
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
            onPressed: () => _onItemTapped(0), // Switch to home tab
            child: const Text('Start a Debate'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    final dashboardState = context.findAncestorStateOfType<_DashboardScreenState>();
    if (dashboardState != null) {
      dashboardState._onItemTapped(index);
    }
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

class RoadmapTab extends StatefulWidget {
  const RoadmapTab({Key? key}) : super(key: key);

  @override
  State<RoadmapTab> createState() => _RoadmapTabState();
}

class _RoadmapTabState extends State<RoadmapTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: AppConstants.skillCategories.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final skills = user?.skills;
    
    return Column(
      children: [
        // Header section with progress overview
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Learning Roadmap',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personalized resources to improve your debate skills',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              // Overall progress indicator
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          value: ((user?.completedResources.length ?? 0) > 0) 
                              ? (user!.completedResources.length / (user.completedResources.length + 5)) 
                              : 0.05,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          color: Colors.white,
                          strokeWidth: 6,
                        ),
                      ),
                      Icon(Icons.insights, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learning Progress', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user?.completedResources.length ?? 0} resources completed',
                          style: TextStyle(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Enhanced tab bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: AppConstants.skillCategories.map((skill) => Tab(
              text: skill,
              icon: Icon(_getSkillIcon(skill)),
            )).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Consumer2<FeedbackProvider, UserProvider>(
            builder: (context, feedbackProvider, userProvider, child) {
              final isLoading = feedbackProvider.isLoading;
              
              if (isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              return TabBarView(
                controller: _tabController,
                children: AppConstants.skillCategories.map((skill) {
                  final skillKey = skill.toLowerCase().replaceAll(' ', '');
                  final resources = feedbackProvider.getResourcesBySkill(skillKey);
                  
                  return _buildResourceList(
                    context,
                    skill,
                    resources,
                    userProvider,
                    feedbackProvider,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResourceList(
    BuildContext context,
    String skill,
    List<LearningResource> resources,
    UserProvider userProvider,
    FeedbackProvider feedbackProvider,
  ) {
    if (resources.isEmpty) {
      // Add sample resources for empty states
      List<Map<String, dynamic>> sampleResources = [
        {
          'title': 'Introduction to ${skill}',
          'type': 'article',
          'description': 'Learn the fundamentals of ${skill.toLowerCase()} to improve your debate performance.',
          'isRecommended': true,
        },
        {
          'title': 'Advanced ${skill} Techniques',
          'type': 'video',
          'description': 'Watch this comprehensive guide on mastering ${skill.toLowerCase()} in competitive debates.',
          'isRecommended': false,
        }
      ];
      
      // Use ListView instead of Column to make it scrollable
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Empty state header with icon
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevent Column from trying to fill available space
              children: [
                Icon(
                  _getSkillIcon(skill),
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No personalized resources yet',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Complete more debates to get customized resources for your skill development',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.go(AppConstants.routeTextDebate),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start a Debate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Suggested general resources section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested General Resources',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Sample resource cards
          ...sampleResources.map((resource) => _buildSampleResourceCard(context, resource, skill)).toList(),
        ],
      );
    }
    
    final user = userProvider.user;
    final completedResources = user?.completedResources ?? [];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        final isCompleted = completedResources.contains(resource.id) || resource.isCompleted;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Stack(
                  children: [
                    _buildResourceTypeIcon(resource.type),
                    if (isCompleted)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  resource.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getResourceTypeColor(resource.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      resource.type.substring(0, 1).toUpperCase() + resource.type.substring(1),
                      style: TextStyle(
                        color: _getResourceTypeColor(resource.type),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.description,
                      style: TextStyle(height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    // Target skills section
                    if (resource.targetSkills.isNotEmpty) ...[  
                      Text(
                        'Focuses on:',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: resource.targetSkills.map((skill) => Chip(
                          label: Text(
                            skill.substring(0, 1).toUpperCase() + skill.substring(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          padding: const EdgeInsets.all(4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          avatar: Icon(_getSkillIcon(skill), size: 16),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Bottom actions section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Resource URL button
                        if (resource.url.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () {
                              // Launch URL functionality would go here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening ${resource.title}...'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Open'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          
                        // Complete button
                        if (!isCompleted)
                          ElevatedButton.icon(
                            onPressed: () async {
                              await userProvider.markResourceCompleted(resource.id);
                              await feedbackProvider.markResourceCompleted(resource.id);
                              await userProvider.addPoints(AppConstants.pointsPerResourceCompleted);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${resource.title} marked as completed'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Mark Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourceTypeIcon(String type) {
    IconData iconData;
    Color color;
    
    switch (type.toLowerCase()) {
      case 'video':
        iconData = Icons.video_library;
        color = Colors.red;
        break;
      case 'article':
        iconData = Icons.article;
        color = Colors.blue;
        break;
      case 'exercise':
        iconData = Icons.fitness_center;
        color = Colors.orange;
        break;
      case 'podcast':
        iconData = Icons.headphones;
        color = Colors.green;
        break;
      case 'quiz':
        iconData = Icons.quiz;
        color = Colors.amber;
        break;
      default:
        iconData = Icons.book;
        color = Colors.purple;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }
  
  // Get appropriate icon for each skill category
  IconData _getSkillIcon(String skill) {
    switch (skill.toLowerCase()) {
      case 'clarity':
        return Icons.lightbulb_outline;
      case 'reasoning':
        return Icons.psychology;
      case 'evidence':
        return Icons.fact_check;
      case 'persuasion':
        return Icons.record_voice_over;
      case 'rebuttal':
        return Icons.gavel;
      case 'structure':
        return Icons.architecture;
      default:
        return Icons.school;
    }
  }
  
  // Get color for resource type
  Color _getResourceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.red;
      case 'article':
        return Colors.blue;
      case 'exercise':
        return Colors.orange;
      case 'podcast':
        return Colors.green;
      case 'quiz':
        return Colors.amber;
      default:
        return Colors.purple;
    }
  }
  
  // Build sample resource card for empty states
  Widget _buildSampleResourceCard(BuildContext context, Map<String, dynamic> resource, String category) {
    final title = resource['title'] as String;
    final type = resource['type'] as String;
    final description = resource['description'] as String;
    final isRecommended = resource['isRecommended'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
          width: isRecommended ? 2 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  'Recommended for you',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getResourceTypeColor(type).withOpacity(0.2),
              child: Icon(_getResourceTypeIcon(type), color: _getResourceTypeColor(type)),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getResourceTypeColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type.substring(0, 1).toUpperCase() + type.substring(1),
                  style: TextStyle(
                    color: _getResourceTypeColor(type),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(
                        category,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      padding: const EdgeInsets.all(4),
                      avatar: Icon(_getSkillIcon(category), size: 16),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppConstants.routeTextDebate),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Start Debate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to get IconData with correct type for _buildResourceTypeIcon method
  IconData _getResourceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.video_library;
      case 'article':
        return Icons.article;
      case 'exercise':
        return Icons.fitness_center;
      case 'podcast':
        return Icons.headphones;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.book;
    }
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        
        if (user == null) {
          return const Center(
            child: Text('User not found'),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced profile header with gradient background
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile info
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          // Profile image with edit button
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: () => _showEditProfileDialog(context, user, userProvider),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildBadge(user.points),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Quick stats row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickStat(context, 'Points', user.points.toString(), Icons.stars),
                          _buildQuickStat(context, 'Debates', (user.completedResources.length / 2).round().toString(), Icons.mic),
                          _buildQuickStat(context, 'Resources', user.completedResources.length.toString(), Icons.book),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats section with cards
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Your Stats',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _shareStats(context, user),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200, // Increased height to prevent overflow
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildStatCard(
                      context, 
                      'Debate Score', 
                      '${(user.points / 10).round()}', 
                      Icons.leaderboard,
                      Colors.orange.shade400,
                      'Based on your performance in previous debates',
                    ),
                    _buildStatCard(
                      context, 
                      'Debates', 
                      (user.completedResources.length / 2).round().toString(), 
                      Icons.record_voice_over,
                      Colors.blue.shade400,
                      'Total debates completed across all modes',
                    ),
                    _buildStatCard(
                      context, 
                      'Resources', 
                      user.completedResources.length.toString(), 
                      Icons.menu_book,
                      Colors.green.shade400,
                      'Learning resources completed',
                    ),
                    _buildStatCard(
                      context, 
                      'Streak', 
                      '${user.points > 500 ? 5 : (user.points / 100).round()}', 
                      Icons.local_fire_department,
                      Colors.red.shade400,
                      'Consecutive days of activity',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Skills section with radar chart option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Your Skills',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _toggleSkillsView(context),
                      icon: const Icon(Icons.pie_chart, size: 18),
                      label: const Text('Chart View'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (user.skills != null && user.skills!.isNotEmpty)
                        ...user.skills!.entries.map((entry) {
                          final skill = entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1);
                          final value = entry.value;
                          final icon = _getSkillIcon(entry.key);
                          final color = _getSkillColor(entry.key);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(icon, color: color, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      skill,
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${(value * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: color.withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getSkillMessage(skill, value),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList()
                      else
                        Column(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 48,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Complete debates to see your skill ratings',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.go(AppConstants.routeTextDebate),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start a Debate'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Enhanced Settings section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Settings & Preferences',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Column(
                  children: [
                    // App appearance settings
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16, height: 8),
                    _buildThemeToggle(context),
                    ListTile(
                      leading: const Icon(Icons.text_fields),
                      title: const Text('Text Size'),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'S', label: Text('S')),
                          ButtonSegment(value: 'M', label: Text('M')),
                          ButtonSegment(value: 'L', label: Text('L')),
                        ],
                        selected: {'M'},
                        onSelectionChanged: (newSelection) {
                          // Handle text size change
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Text size setting coming soon')),
                          );
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    
                    // Voice settings section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mic,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Voice Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16, height: 8),
                    _buildVoiceSettings(context),
                    
                    // Account & Help section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Account & Support',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(indent: 16, endIndent: 16, height: 8),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notifications'),
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {
                          // Handle notification setting change
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification settings coming soon')),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Help center coming soon')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Terms page coming soon')),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red.shade300),
                      title: Text('Sign Out', style: TextStyle(color: Colors.red.shade300)),
                      onTap: () => _showSignOutDialog(context),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(int points) {
    final badgeLevel = Utils.getBadgeLevel(points);
    
    Color badgeColor;
    switch (badgeLevel) {
      case 'Platinum':
        badgeColor = Colors.blueGrey;
        break;
      case 'Gold':
        badgeColor = Colors.amber;
        break;
      case 'Silver':
        badgeColor = Colors.grey;
        break;
      case 'Bronze':
        badgeColor = Colors.brown;
        break;
      default:
        badgeColor = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$badgeLevel Debater',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          title: const Text('Dark Mode'),
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          ),
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.setDarkMode(value);
          },
        );
      },
    );
  }

  Widget _buildVoiceSettings(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return ExpansionTile(
          leading: const Icon(Icons.settings_voice),
          title: const Text('Voice Settings'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Speech Rate',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: audioProvider.speechRate,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: audioProvider.speechRate.toStringAsFixed(1),
                    onChanged: (value) {
                      audioProvider.setSpeechRate(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Voice Pitch',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: audioProvider.pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: audioProvider.pitch.toStringAsFixed(1),
                    onChanged: (value) {
                      audioProvider.setPitch(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  // New helper methods for the enhanced Profile UI
  
  // Build quick stats in profile header
  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
  
  // Build stat card for the stats section
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, String description) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
          ),
          
          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Show edit profile dialog
  void _showEditProfileDialog(BuildContext context, User user, UserProvider userProvider) {
    final nameController = TextEditingController(text: user.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email cannot be changed',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && nameController.text != user.name) {
                // Create updated user object with new name
                final updatedUser = user.copyWith(name: nameController.text);
                // Update user using the existing method
                userProvider.updateUser(updatedUser);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Share user stats
  void _shareStats(BuildContext context, User user) {
    final skillsText = user.skills != null && user.skills!.isNotEmpty
        ? user.skills!.entries.map((e) => '${e.key}: ${(e.value * 100).toStringAsFixed(0)}%').join('\n')
        : 'No skills data yet';
    
    final shareText = """🎯 My ArgueAI Stats 🎯
    
Debate Score: ${(user.points / 10).round()}
Debates Completed: ${(user.completedResources.length / 2).round()}
Resources Completed: ${user.completedResources.length}

My Skills:
$skillsText

Download ArgueAI and improve your debate skills!""";
    
    // In a real app, this would use the share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing is not implemented in this demo'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Share Preview'),
                content: SingleChildScrollView(
                  child: Text(shareText),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Toggle between list and chart views for skills
  void _toggleSkillsView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skill Visualization'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Radar Chart View Coming Soon',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This feature will show your skills in a visual radar/spider chart format.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Show sign out confirmation dialog
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Handle sign out
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign out functionality coming soon')),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  
  // Get color for different skills
  Color _getSkillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'clarity':
        return Colors.blue;
      case 'reasoning':
        return Colors.green;
      case 'evidence':
        return Colors.orange;
      case 'persuasion':
        return Colors.purple;
      case 'rebuttal':
        return Colors.red;
      case 'structure':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }
  
  // Get personalized message based on skill level
  String _getSkillMessage(String skill, double value) {
    if (value < 0.3) {
      return 'Emerging skill, continue practicing';
    } else if (value < 0.6) {
      return 'Good progress, keep improving';
    } else if (value < 0.8) {
      return 'Strong skill, nearly mastered';
    } else {
      return 'Excellent mastery of this skill';
    }
  }
  
  // Get appropriate icon for each skill category
  IconData _getSkillIcon(String skill) {
    switch (skill.toLowerCase()) {
      case 'clarity':
        return Icons.lightbulb_outline;
      case 'reasoning':
        return Icons.psychology;
      case 'evidence':
        return Icons.fact_check;
      case 'persuasion':
        return Icons.record_voice_over;
      case 'rebuttal':
        return Icons.gavel;
      case 'structure':
        return Icons.architecture;
      default:
        return Icons.school;
    }
  }
}
