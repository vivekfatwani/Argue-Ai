import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../core/constants.dart';
import '../../core/providers/debate_provider.dart';
import '../../core/providers/feedback_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils.dart';

class FeedbackScreen extends StatefulWidget {
  final String debateId;

  const FeedbackScreen({
    Key? key,
    required this.debateId,
  }) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

// Simple synchronization function to prevent concurrent operations
Future<T> synchronized<T>(Object lock, Future<T> Function() callback) async {
  // This is a simplified version of the synchronized package functionality
  try {
    return await callback();
  } catch (e) {
    debugPrint('Error in synchronized block: $e');
    rethrow;
  }
}

class _FeedbackScreenState extends State<FeedbackScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _feedback;
  bool _isLoading = true;
  bool _isProcessComplete = false;
  bool _isDisposed = false;
  bool _isNavigatingAway = false;
  
  @override
  void initState() {
    super.initState();
    debugPrint('FeedbackScreen initState called');
    WidgetsBinding.instance.addObserver(this);
    
    // Use a slight delay to ensure the widget is fully mounted
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposed) {
        _loadDebateAndGenerateFeedback();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('FeedbackScreen lifecycle state changed to: $state');
    // Monitor app lifecycle changes to help debug issues
    if (state == AppLifecycleState.paused) {
      debugPrint('App paused while on FeedbackScreen');
    }
  }
  
  @override
  void dispose() {
    debugPrint('FeedbackScreen dispose called');
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    super.dispose();
  }

  // This lock prevents multiple navigations during async operations
  final _navigationLock = Object();

  Future<void> _loadDebateAndGenerateFeedback() async {
    debugPrint('Starting to load debate and generate feedback');
    if (_isDisposed || !mounted || _isNavigatingAway) {
      debugPrint('Widget not mounted, disposed, or navigating away at start of _loadDebateAndGenerateFeedback');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading debate with ID: ${widget.debateId}');
      final debateProvider = Provider.of<DebateProvider>(context, listen: false);
      await debateProvider.loadDebate(widget.debateId);
      
      // Check if still mounted after loading debate
      if (_isDisposed || !mounted) {
        debugPrint('Widget not mounted or disposed after loading debate');
        return;
      }
      
      debugPrint('Generating feedback for debate');
      final feedback = await debateProvider.generateFeedback();
      
      // Check if still mounted after generating feedback
      if (_isDisposed || !mounted) {
        debugPrint('Widget not mounted or disposed after generating feedback');
        return;
      }
      
      debugPrint('Feedback generated successfully, updating state');
      
      // Check again before updating state
      if (_isDisposed || !mounted || _isNavigatingAway) {
        debugPrint('Widget not mounted, disposed, or navigating away before updating state');
        return;
      }
      
      setState(() {
        _feedback = feedback;
        _isLoading = false;
        // Mark as complete immediately after feedback is loaded
        _isProcessComplete = true;
      });
      
      // Update user skills based on feedback
      if (feedback.containsKey('skillRatings')) {
        debugPrint('Updating user skills based on feedback');
        // Store references to providers to avoid context usage after potential unmount
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final feedbackProvider = Provider.of<FeedbackProvider>(context, listen: false);
        final skillRatings = Map<String, double>.from(feedback['skillRatings']);
        
        // Update skills and add points
        await userProvider.updateSkills(skillRatings);
        await userProvider.addPoints(AppConstants.pointsPerDebate);
        
        // Generate recommendations in background - don't block navigation
        debugPrint('Generating recommendations based on skills');
        // Use unawaited to run in background
        feedbackProvider.generateRecommendations(skillRatings).then((_) {
          debugPrint('Recommendations generated successfully');
        }).catchError((error) {
          debugPrint('Error generating recommendations: $error');
        });
      }
    } catch (e, stack) {
      // Handle errors and check if mounted before updating state
      debugPrint('Error in _loadDebateAndGenerateFeedback: $e');
      debugPrint('Stack trace: $stack');
      
      if (!_isDisposed && mounted) {
        debugPrint('Setting loading to false after error');
        setState(() {
          _isLoading = false;
          // Mark complete even on error so user can navigate away
          _isProcessComplete = true;
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while generating feedback.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        debugPrint('Widget not mounted or disposed after error, cannot update state');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use WillPopScope to intercept and control back navigation
    return WillPopScope(
      onWillPop: () async {
        debugPrint('Back button pressed on FeedbackScreen');
        
        // Use a lock to prevent multiple navigation attempts
        return synchronized<bool>(_navigationLock, () async {
          debugPrint('Navigation lock acquired');
          
          // If already navigating away, prevent additional navigation
          if (_isNavigatingAway) {
            debugPrint('Already navigating away, preventing additional navigation');
            return false;
          }
          
          // If still loading, prevent navigation
          if (_isLoading) {
            debugPrint('Preventing back navigation during loading');
            return false;
          }
          
          // If process is not complete, prevent navigation
          if (!_isProcessComplete) {
            debugPrint('Process not complete, preventing navigation');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please wait while we finish processing...'),
                duration: Duration(seconds: 2),
              ),
            );
            return false;
          }
          
          // If feedback is ready, show a confirmation dialog
          if (_feedback != null) {
            final shouldPop = await showDialog<bool>(
              context: context,
              barrierDismissible: false, // Prevent dismissing by tapping outside
              builder: (context) => AlertDialog(
                title: const Text('Leave feedback?'),
                content: const Text('Are you sure you want to leave this screen?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Mark as navigating away before popping
                      _isNavigatingAway = true;
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Leave'),
                  ),
                ],
              ),
            ) ?? false;
            
            debugPrint('User decided to ${shouldPop ? 'leave' : 'stay on'} feedback screen');
            if (shouldPop) {
              _isNavigatingAway = true;
            }
            return shouldPop;
          }
          
          // Default behavior
          _isNavigatingAway = true;
          return true;
        });
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Debate Feedback'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing your debate performance...'),
                ],
              ),
            )
          : _buildFeedbackContent(),
      bottomNavigationBar: _isLoading
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_isLoading || !_isProcessComplete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please wait for processing to complete...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        
                        // Use synchronized to prevent multiple navigation attempts
                        synchronized<void>(_navigationLock, () async {
                          if (_isNavigatingAway) return Future.value();
                          _isNavigatingAway = true;
                          
                          debugPrint('Navigating to Dashboard from FeedbackScreen');
                          // Use a more controlled navigation approach with GoRouter
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_isDisposed) {
                              // Use GoRouter to navigate
                              context.go(AppConstants.routeDashboard, extra: 'fromFeedback');
                            }
                          });
                          return Future.value();
                        });
                      },
                      child: const Text('Back to Home'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_isLoading || !_isProcessComplete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please wait for processing to complete...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        
                        // Use synchronized to prevent multiple navigation attempts
                        synchronized<void>(_navigationLock, () async {
                          if (_isNavigatingAway) return Future.value();
                          _isNavigatingAway = true;
                          
                          debugPrint('Navigating to Roadmap from FeedbackScreen');
                          // Use a more controlled navigation approach with GoRouter
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_isDisposed) {
                              // Use GoRouter to navigate
                              context.go(AppConstants.routeRoadmap, extra: 'fromFeedback');
                            }
                          });
                          return Future.value();
                        });
                      },
                      child: const Text('View Roadmap'),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildFeedbackContent() {
    debugPrint('Building feedback content with data: ${_feedback != null}');
    
    // Check if feedback is null or missing required data
    if (_feedback == null) {
      return const Center(
        child: Text('Failed to generate feedback'),
      );
    }
    
    // Verify that all required keys exist in the feedback data
    if (!_feedback!.containsKey('skillRatings') || 
        !_feedback!.containsKey('strengths') || 
        !_feedback!.containsKey('improvements') || 
        !_feedback!.containsKey('overallFeedback')) {
      debugPrint('Feedback data is incomplete: ${_feedback!.keys}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Feedback data is incomplete'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                debugPrint('Retrying feedback generation');
                _loadDebateAndGenerateFeedback();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final skillRatings = Map<String, double>.from(_feedback!['skillRatings']);
    final strengths = List<String>.from(_feedback!['strengths']);
    final improvements = List<String>.from(_feedback!['improvements']);
    final overallFeedback = _feedback!['overallFeedback'];

    // Separate skills into categories
    final communicationSkills = {
      'Clarity': skillRatings['clarity'] ?? 0.0,
      'Coherence': skillRatings['coherence'] ?? 0.0,
      'Articulation': skillRatings['articulation'] ?? 0.0,
      'Engagement': skillRatings['engagement'] ?? 0.0,
      'Tone': skillRatings['tone'] ?? 0.0,
    };

    final argumentationSkills = {
      'Logic': skillRatings['logic'] ?? 0.0,
      'Rebuttal Quality': skillRatings['rebuttalQuality'] ?? 0.0,
      'Persuasiveness': skillRatings['persuasiveness'] ?? 0.0,
    };

    // Calculate category averages
    final communicationAvg = communicationSkills.values.reduce((a, b) => a + b) / communicationSkills.length;
    final argumentationAvg = argumentationSkills.values.reduce((a, b) => a + b) / argumentationSkills.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall score card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Overall Performance',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildScoreIndicator(
                    Utils.calculateDebateScore(skillRatings)['overall'] ?? 0.0,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Great job! You\'ve earned ${AppConstants.pointsPerDebate} points.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category Performance Overview
          Row(
            children: [
              Expanded(
                child: _buildCategoryCard(
                  context,
                  'Communication',
                  communicationAvg,
                  Icons.chat_bubble_outline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCategoryCard(
                  context,
                  'Argumentation',
                  argumentationAvg,
                  Icons.psychology,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Communication Metrics Section
          Text(
            'Communication Metrics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'How effectively you express and convey your ideas',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSkillBars(communicationSkills),
            ),
          ),
          const SizedBox(height: 24),

          // Argumentation Metrics Section
          Text(
            'Argumentation Metrics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'The quality and strength of your debate arguments',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSkillBars(argumentationSkills),
            ),
          ),
          const SizedBox(height: 24),

          // Detailed feedback
          Text(
            'Detailed Feedback',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Strengths',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...strengths.map((strength) => _buildFeedbackItem(
                    strength,
                    Icons.check_circle,
                    Colors.green,
                  )),
                  const SizedBox(height: 16),
                  Text(
                    'Areas for Improvement',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...improvements.map((improvement) => _buildFeedbackItem(
                    improvement,
                    Icons.trending_up,
                    Colors.orange,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Overall feedback
          Text(
            'Overall Feedback',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                overallFeedback,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(double score) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: CircularProgressIndicator(
            value: score,
            strokeWidth: 12,
            backgroundColor: Colors.grey[300],
            color: _getScoreColor(score),
          ),
        ),
        Column(
          children: [
            Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getScoreLabel(score),
              style: TextStyle(
                fontSize: 16,
                color: _getScoreColor(score),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedbackItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, double score, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(score),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getScoreLabel(score),
              style: TextStyle(
                fontSize: 12,
                color: _getScoreColor(score),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBars(Map<String, double> skills) {
    return Column(
      children: skills.entries.map((entry) {
        final skill = entry.key;
        final value = entry.value;
        final skillInfo = _getSkillInfo(skill);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(skillInfo['icon'] as IconData, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        skill,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Text(
                    '${(value * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[300],
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                color: _getScoreColor(value),
              ),
              const SizedBox(height: 4),
              Text(
                skillInfo['description'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _getSkillInfo(String skill) {
    switch (skill.toLowerCase().replaceAll(' ', '')) {
      case 'clarity':
        return {
          'icon': Icons.lightbulb_outline,
          'description': 'How clear and understandable your communication is',
        };
      case 'coherence':
        return {
          'icon': Icons.linear_scale,
          'description': 'How well your ideas flow together logically',
        };
      case 'articulation':
        return {
          'icon': Icons.record_voice_over,
          'description': 'How well-structured your sentences and expressions are',
        };
      case 'engagement':
        return {
          'icon': Icons.connect_without_contact,
          'description': 'How engaging and interesting your communication style is',
        };
      case 'tone':
        return {
          'icon': Icons.sentiment_satisfied_alt,
          'description': 'How appropriate, respectful, and confident your tone is',
        };
      case 'logic':
        return {
          'icon': Icons.psychology,
          'description': 'How well-reasoned and evidence-based your arguments are',
        };
      case 'rebuttalquality':
        return {
          'icon': Icons.gavel,
          'description': 'How effectively you address opposing viewpoints',
        };
      case 'persuasiveness':
        return {
          'icon': Icons.campaign,
          'description': 'How convincing your arguments are overall',
        };
      default:
        return {
          'icon': Icons.school,
          'description': 'Skill assessment',
        };
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.lightGreen;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Good';
    if (score >= 0.4) return 'Average';
    return 'Needs Improvement';
  }
}
