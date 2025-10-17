import 'dart:convert';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../models/debate_model.dart';
import '../models/feedback_model.dart';
import '../constants.dart';
import '../utils.dart';

class StorageService {
  late SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  // Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Get the current user ID, if any
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
  
  // User Profile Methods
  Future<User?> getUser() async {
    final userJson = _prefs.getString(AppConstants.keyUserProfile);
    if (userJson == null) return null;
    
    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }
  
  Future<bool> saveUser(User user) async {
    return await _prefs.setString(
      AppConstants.keyUserProfile,
      jsonEncode(user.toJson()),
    );
  }
  
  Future<bool> clearUser() async {
    return await _prefs.remove(AppConstants.keyUserProfile);
  }
  
  // Debate History Methods
  Future<List<Debate>> getDebateHistory() async {
    List<Debate> debates = [];
    
    // Try to get debates from Firestore first if user is logged in
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('debates')
            .get();
            
        if (snapshot.docs.isNotEmpty) {
          debates = snapshot.docs.map((doc) {
            final data = doc.data();
            // Convert Timestamp to DateTime
            data['startTime'] = (data['startTime'] as Timestamp).toDate().toIso8601String();
            if (data['endTime'] != null) {
              data['endTime'] = (data['endTime'] as Timestamp).toDate().toIso8601String();
            }
            // Ensure messages are properly formatted
            if (data['messages'] != null) {
              final List<dynamic> messages = data['messages'];
              for (var i = 0; i < messages.length; i++) {
                if (messages[i]['timestamp'] is Timestamp) {
                  messages[i]['timestamp'] = (messages[i]['timestamp'] as Timestamp).toDate().toIso8601String();
                }
              }
            }
            return Debate.fromJson(data);
          }).toList();
        }
      } catch (e) {
        print('Error fetching debates from Firestore: $e');
        // Fallback to local storage if Firestore fails
      }
    }
    
    // If no debates found in Firestore or user is not logged in, try local storage
    if (debates.isEmpty) {
      final historyJson = _prefs.getString(AppConstants.keyDebateHistory);
      if (historyJson != null) {
        try {
          final List<dynamic> historyList = jsonDecode(historyJson);
          debates = historyList.map((item) => Debate.fromJson(item)).toList();
        } catch (e) {
          print('Error parsing debate history from local storage: $e');
        }
      }
    }
    
    return debates;
  }
  
  Future<bool> saveDebate(Debate debate) async {
    bool success = true;
    final history = await getDebateHistory();
    
    // Check if debate already exists in local history
    final index = history.indexWhere((d) => d.id == debate.id);
    if (index >= 0) {
      history[index] = debate;
    } else {
      history.add(debate);
    }
    
    // Save to local storage
    success = await _prefs.setString(
      AppConstants.keyDebateHistory,
      jsonEncode(history.map((d) => d.toJson()).toList()),
    );
    
    // Also save to Firestore if user is authenticated
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        final debateMap = debate.toJson();
        
        // Convert DateTime objects to Timestamps for Firestore
        debateMap['startTime'] = Timestamp.fromDate(DateTime.parse(debateMap['startTime']));
        if (debateMap['endTime'] != null) {
          debateMap['endTime'] = Timestamp.fromDate(DateTime.parse(debateMap['endTime']));
        }
        
        // Convert message timestamps
        if (debateMap['messages'] != null) {
          final List<dynamic> messages = debateMap['messages'];
          for (var i = 0; i < messages.length; i++) {
            if (messages[i]['timestamp'] != null) {
              messages[i]['timestamp'] = Timestamp.fromDate(DateTime.parse(messages[i]['timestamp']));
            }
          }
        }
        
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('debates')
            .doc(debate.id)
            .set(debateMap);
            
        print('Debate saved to Firestore successfully: ${debate.id}');
      } catch (e) {
        print('Error saving debate to Firestore: $e');
        success = false;
      }
    }
    
    return success;
  }
  
  Future<bool> deleteDebate(String debateId) async {
    bool success = true;
    final history = await getDebateHistory();
    history.removeWhere((d) => d.id == debateId);
    
    // Update local storage
    success = await _prefs.setString(
      AppConstants.keyDebateHistory,
      jsonEncode(history.map((d) => d.toJson()).toList()),
    );
    
    // Also delete from Firestore if user is authenticated
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('debates')
            .doc(debateId)
            .delete();
            
        print('Debate deleted from Firestore successfully: $debateId');
      } catch (e) {
        print('Error deleting debate from Firestore: $e');
        success = false;
      }
    }
    
    return success;
  }
  
  // User Skills Methods
  Future<Map<String, double>> getUserSkills() async {
    Map<String, double> defaultSkills = {
      'clarity': 0.0,
      'reasoning': 0.0,
      'evidence': 0.0,
      'persuasion': 0.0,
      'rebuttal': 0.0,
      'structure': 0.0,
    };
    
    // Try to get skills from Firestore first if user is logged in
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        final docSnapshot = await _firestore.collection('users').doc(userId).get();
        
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('skills')) {
          final skills = docSnapshot.data()!['skills'] as Map<String, dynamic>;
          return Map<String, double>.from(skills.map((key, value) => 
              MapEntry(key, value is double ? value : value is int ? value.toDouble() : 0.0)));
        }
      } catch (e) {
        print('Error fetching skills from Firestore: $e');
        // Fallback to local storage if Firestore fails
      }
    }
    
    // If no skills found in Firestore or user is not logged in, try local storage
    final skillsJson = _prefs.getString(AppConstants.keyUserSkills);
    if (skillsJson != null) {
      try {
        return Map<String, double>.from(jsonDecode(skillsJson));
      } catch (e) {
        print('Error parsing user skills from local storage: $e');
      }
    }
    
    return defaultSkills;
  }
  
  Future<bool> saveUserSkills(Map<String, double> skills) async {
    bool success = true;
    
    // Save to local storage
    success = await _prefs.setString(
      AppConstants.keyUserSkills,
      jsonEncode(skills),
    );
    
    // Also save to Firestore if user is authenticated
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        await _firestore.collection('users').doc(userId).update({
          'skills': skills
        });
        print('Skills saved to Firestore successfully');
      } catch (e) {
        print('Error saving skills to Firestore: $e');
        success = false;
      }
    }
    
    return success;
  }
  
  // Learning Resources Methods
  Future<List<LearningResource>> getLearningResources() async {
    List<LearningResource> resources = [];
    
    // Try to get resources from Firestore first if user is logged in
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('resources')
            .get();
            
        if (snapshot.docs.isNotEmpty) {
          resources = snapshot.docs.map((doc) {
            return LearningResource.fromJson(doc.data());
          }).toList();
          
          // Also update local storage for offline access
          await _prefs.setString(
            'learning_resources',
            jsonEncode(resources.map((r) => r.toJson()).toList()),
          );
          
          return resources;
        }
      } catch (e) {
        print('Error fetching resources from Firestore: $e');
        // Fallback to local storage if Firestore fails
      }
    }
    
    // If no resources found in Firestore or user is not logged in, try local storage
    final resourcesJson = _prefs.getString('learning_resources');
    if (resourcesJson != null) {
      try {
        final List<dynamic> resourcesList = jsonDecode(resourcesJson);
        resources = resourcesList.map((item) => LearningResource.fromJson(item)).toList();
      } catch (e) {
        print('Error parsing learning resources from local storage: $e');
      }
    }
    
    return resources;
  }
  
  Future<bool> saveLearningResources(List<LearningResource> resources) async {
    bool success = true;
    
    // Save to local storage
    success = await _prefs.setString(
      'learning_resources',
      jsonEncode(resources.map((r) => r.toJson()).toList()),
    );
    
    // Also save to Firestore if user is authenticated
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        final batch = _firestore.batch();
        
        // Get reference to resources collection
        final resourcesRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('resources');
            
        // Create a batch write to update all resources
        for (final resource in resources) {
          final resourceDoc = resourcesRef.doc(resource.id);
          batch.set(resourceDoc, resource.toJson());
        }
        
        // Execute the batch
        await batch.commit();
        print('${resources.length} resources saved to Firestore successfully');
      } catch (e) {
        print('Error saving resources to Firestore: $e');
        success = false;
      }
    }
    
    return success;
  }
  
  Future<bool> markResourceCompleted(String resourceId) async {
    final resources = await getLearningResources();
    final index = resources.indexWhere((r) => r.id == resourceId);
    
    if (index >= 0) {
      resources[index] = resources[index].copyWith(isCompleted: true);
      
      // Update in local storage
      bool localSuccess = await _prefs.setString(
        'learning_resources',
        jsonEncode(resources.map((r) => r.toJson()).toList()),
      );
      
      // Also update in Firestore if user is authenticated
      if (isAuthenticated) {
        try {
          final userId = currentUserId!;
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('resources')
              .doc(resourceId)
              .update({'isCompleted': true});
              
          // Update user's completedResources in their profile document
          await _firestore
              .collection('users')
              .doc(userId)
              .update({
                'completedResources': FieldValue.arrayUnion([resourceId])
              });
              
          print('Resource marked completed in Firestore: $resourceId');
          return true;
        } catch (e) {
          print('Error marking resource completed in Firestore: $e');
          return localSuccess;
        }
      }
      
      return localSuccess;
    }
    
    return false;
  }
  
  // User Preferences Methods
  Future<Map<String, dynamic>> getUserPreferences() async {
    Map<String, dynamic> defaultPrefs = {
      'darkMode': false,
      'notificationsEnabled': true,
      'voiceSpeed': 1.0,
      'voicePitch': 1.0,
    };
    
    // Try to get preferences from Firestore first if user is logged in
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        final docSnapshot = await _firestore.collection('users').doc(userId).get();
        
        if (docSnapshot.exists && docSnapshot.data()!.containsKey('preferences')) {
          return Map<String, dynamic>.from(docSnapshot.data()!['preferences']);
        }
      } catch (e) {
        print('Error fetching preferences from Firestore: $e');
        // Fallback to local storage if Firestore fails
      }
    }
    
    // If no preferences found in Firestore or user is not logged in, try local storage
    final prefsJson = _prefs.getString(AppConstants.keyUserPreferences);
    if (prefsJson != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(prefsJson));
      } catch (e) {
        print('Error parsing user preferences from local storage: $e');
      }
    }
    
    return defaultPrefs;
  }
  
  Future<bool> saveUserPreferences(Map<String, dynamic> preferences) async {
    bool success = true;
    
    // Save to local storage
    success = await _prefs.setString(
      AppConstants.keyUserPreferences,
      jsonEncode(preferences),
    );
    
    // Also save to Firestore if user is authenticated
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        await _firestore.collection('users').doc(userId).update({
          'preferences': preferences
        });
        print('Preferences saved to Firestore successfully');
      } catch (e) {
        print('Error saving preferences to Firestore: $e');
        success = false;
      }
    }
    
    return success;
  }
  
  // Sync local data with Firestore
  Future<bool> syncWithFirestore() async {
    if (!isAuthenticated) return false;
    
    try {
      final userId = currentUserId!;
      
      // Sync user skills
      final localSkills = await getUserSkills();
      await _firestore.collection('users').doc(userId).update({
        'skills': localSkills,
        'lastSynced': FieldValue.serverTimestamp(),
      });
      
      // Sync debates
      final localDebates = await getDebateHistory();
      final batch = _firestore.batch();
      
      for (final debate in localDebates) {
        final debateMap = debate.toJson();
        
        // Convert DateTime objects to Timestamps for Firestore
        debateMap['startTime'] = Timestamp.fromDate(DateTime.parse(debateMap['startTime']));
        if (debateMap['endTime'] != null) {
          debateMap['endTime'] = Timestamp.fromDate(DateTime.parse(debateMap['endTime']));
        }
        
        // Convert message timestamps
        if (debateMap['messages'] != null) {
          final List<dynamic> messages = debateMap['messages'];
          for (var i = 0; i < messages.length; i++) {
            if (messages[i]['timestamp'] != null) {
              messages[i]['timestamp'] = Timestamp.fromDate(DateTime.parse(messages[i]['timestamp']));
            }
          }
        }
        
        batch.set(
          _firestore.collection('users').doc(userId).collection('debates').doc(debate.id),
          debateMap,
          SetOptions(merge: true)
        );
      }
      
      await batch.commit();
      print('Successfully synced local data with Firestore');
      return true;
    } catch (e) {
      print('Error syncing with Firestore: $e');
      return false;
    }
  }
  
  // Clear all stored data
  Future<bool> clearAllData() async {
    bool success = await _prefs.clear();
    
    // Also delete user data from Firestore if authenticated
    if (isAuthenticated) {
      try {
        final userId = currentUserId!;
        
        // Delete debates collection
        final debateSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('debates')
            .get();
            
        final debateBatch = _firestore.batch();
        for (final doc in debateSnapshot.docs) {
          debateBatch.delete(doc.reference);
        }
        await debateBatch.commit();
        
        // Delete resources collection
        final resourceSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('resources')
            .get();
            
        final resourceBatch = _firestore.batch();
        for (final doc in resourceSnapshot.docs) {
          resourceBatch.delete(doc.reference);
        }
        await resourceBatch.commit();
        
        // Update user document to reset skills and preferences
        await _firestore.collection('users').doc(userId).update({
          'skills': {},
          'preferences': {},
          'completedResources': [],
          'points': 0,
        });
        
        print('Successfully cleared user data from Firestore');
      } catch (e) {
        print('Error clearing data from Firestore: $e');
        success = false;
      }
    }
    
    return success;
  }
}
