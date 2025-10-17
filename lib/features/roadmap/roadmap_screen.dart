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
          tabs: AppConstants.skillCategories.map((skill) => Tab(text: skill)).toList(),
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
                        ...resource.targetSkills.map((skill) => Chip(
                          label: Text(
                            skill.substring(0, 1).toUpperCase() + skill.substring(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          padding: const EdgeInsets.all(4),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
}
