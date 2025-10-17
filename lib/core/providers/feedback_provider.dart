import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';

class FeedbackProvider with ChangeNotifier {
  final StorageService _storageService;
  final AIService _aiService;
  
  List<LearningResource> _resources = [];
  bool _isLoading = false;
  
  FeedbackProvider(this._storageService, this._aiService) {
    _loadResources();
  }
  
  List<LearningResource> get resources => _resources;
  bool get isLoading => _isLoading;
  
  // Load learning resources from storage
  Future<void> _loadResources() async {
    _isLoading = true;
    notifyListeners();
    
    _resources = await _storageService.getLearningResources();
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Generate personalized learning recommendations based on skill ratings
  Future<void> generateRecommendations(Map<String, double> skillRatings) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final recommendationsData = await _aiService.generateLearningRecommendations(skillRatings);
      
      final newResources = recommendationsData.map((data) {
        return LearningResource(
          id: data['id'],
          title: data['title'],
          description: data['description'],
          type: data['type'],
          url: data['url'],
          targetSkills: List<String>.from(data['targetSkills']),
        );
      }).toList();
      
      // Add new resources to the existing list, avoiding duplicates
      for (final resource in newResources) {
        if (!_resources.any((r) => r.id == resource.id)) {
          _resources.add(resource);
        }
      }
      
      await _storageService.saveLearningResources(_resources);
    } catch (e) {
      print('Error generating recommendations: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Mark a resource as completed
  Future<void> markResourceCompleted(String resourceId) async {
    final index = _resources.indexWhere((r) => r.id == resourceId);
    
    if (index >= 0) {
      _resources[index] = _resources[index].copyWith(isCompleted: true);
      await _storageService.saveLearningResources(_resources);
      notifyListeners();
    }
  }
  
  // Get resources filtered by skill
  List<LearningResource> getResourcesBySkill(String skill) {
    return _resources.where((resource) => 
      resource.targetSkills.contains(skill)
    ).toList();
  }
  
  // Get completed resources
  List<LearningResource> getCompletedResources() {
    return _resources.where((resource) => resource.isCompleted).toList();
  }
  
  // Get incomplete resources
  List<LearningResource> getIncompleteResources() {
    return _resources.where((resource) => !resource.isCompleted).toList();
  }
  
  // Add a custom resource
  Future<void> addCustomResource(LearningResource resource) async {
    _resources.add(resource);
    await _storageService.saveLearningResources(_resources);
    notifyListeners();
  }
  
  // Remove a resource
  Future<void> removeResource(String resourceId) async {
    _resources.removeWhere((r) => r.id == resourceId);
    await _storageService.saveLearningResources(_resources);
    notifyListeners();
  }
}
