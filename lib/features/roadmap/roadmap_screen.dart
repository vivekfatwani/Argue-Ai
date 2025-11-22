import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/feedback_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/models/feedback_model.dart';
import '../../core/constants.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({Key? key}) : super(key: key);

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: AppConstants.skillCategories.length, vsync: this);
    
    // Debug: Test skill name conversion
    for (var skill in AppConstants.skillCategories) {
      final words = skill.toLowerCase().split(' ');
      final skillKey = words.first + words.skip(1).map((w) => 
        w[0].toUpperCase() + w.substring(1)
      ).join('');
      print('Skill: "$skill" -> Key: "$skillKey" -> Icon: ${_getSkillIcon(skillKey)}');
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Roadmap'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: AppConstants.skillCategories.map((skill) {
            IconData iconData;
            
            // Direct mapping based on skill name
            print('Processing skill: "$skill"');
            switch (skill) {
              case 'Clarity':
                iconData = Icons.lightbulb_outline;
                print('  -> Matched Clarity, icon: $iconData');
                break;
              case 'Coherence':
                iconData = Icons.grain;
                print('  -> Matched Coherence, icon: $iconData');
                break;
              case 'Articulation':
                iconData = Icons.record_voice_over;
                print('  -> Matched Articulation, icon: $iconData');
                break;
              case 'Engagement':
                iconData = Icons.favorite;
                print('  -> Matched Engagement, icon: $iconData');
                break;
              case 'Tone':
                iconData = Icons.tune;
                print('  -> Matched Tone, icon: $iconData');
                break;
              case 'Logic':
                iconData = Icons.psychology;
                print('  -> Matched Logic, icon: $iconData');
                break;
              case 'Rebuttal Quality':
                iconData = Icons.gavel;
                print('  -> Matched Rebuttal Quality, icon: $iconData');
                break;
              case 'Persuasiveness':
                iconData = Icons.campaign;
                print('  -> Matched Persuasiveness, icon: $iconData');
                break;
              default:
                iconData = Icons.star;
                print('  -> NO MATCH, using default star icon');
            }
            
            return Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconData, size: 24),
                  const SizedBox(height: 4),
                  Text(skill, style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Consumer2<FeedbackProvider, UserProvider>(
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
              // Convert skill name to camelCase to match the AI service format
              // "Rebuttal Quality" -> "rebuttalQuality", "Clarity" -> "clarity"
              final words = skill.toLowerCase().split(' ');
              final skillKey = words.first + words.skip(1).map((w) => 
                w[0].toUpperCase() + w.substring(1)
              ).join('');
              
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No resources available for $skill yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete more debates to get personalized recommendations',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: _buildResourceTypeIcon(resource.type),
                title: Text(
                  resource.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(resource.type.substring(0, 1).toUpperCase() + resource.type.substring(1)),
                trailing: isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.description),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ...resource.targetSkills.map((skill) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            avatar: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                _getSkillIcon(skill),
                                size: 16,
                                color: _getSkillColor(skill),
                              ),
                            ),
                            label: Text(
                              _formatSkillName(skill),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getSkillColor(skill).withOpacity(0.1),
                            padding: const EdgeInsets.all(4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )).toList(),
                        const Spacer(),
                        if (!isCompleted)
                          ElevatedButton(
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
                            child: const Text('Mark Complete'),
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
      default:
        iconData = Icons.book;
        color = Colors.purple;
    }
    
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color),
    );
  }

  IconData _getSkillIcon(String skill) {
    switch (skill.toLowerCase()) {
      case 'clarity':
        return Icons.lightbulb_outline;
      case 'coherence':
        return Icons.grain;
      case 'articulation':
        return Icons.record_voice_over;
      case 'engagement':
        return Icons.favorite;
      case 'tone':
        return Icons.tune;
      case 'logic':
        return Icons.psychology;
      case 'rebuttalquality':
        return Icons.gavel;
      case 'persuasiveness':
        return Icons.campaign;
      default:
        return Icons.star;
    }
  }

  Color _getSkillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'clarity':
        return Colors.blue;
      case 'coherence':
        return Colors.indigo;
      case 'articulation':
        return Colors.cyan;
      case 'engagement':
        return Colors.amber;
      case 'tone':
        return Colors.pink;
      case 'logic':
        return Colors.green;
      case 'rebuttalquality':
        return Colors.red;
      case 'persuasiveness':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatSkillName(String skill) {
    // Convert camelCase to Title Case
    String result = skill.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }
}

