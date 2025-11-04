import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user_model.dart';
import '../models/debate_model.dart';
import '../models/feedback_model.dart';

/// Supabase Service - Handles all Supabase operations
/// Replaces Firebase Auth, Firestore, and Storage
class SupabaseService {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  
  // Get current user
  supabase.User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  
  // Auth state stream
  Stream<supabase.AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // ==================== AUTHENTICATION ====================
  
  /// Sign up with email and password
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    
    // Create user profile in database
    if (response.user != null) {
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'points': 0,
        'created_at': DateTime.now().toIso8601String(),
        'last_active': DateTime.now().toIso8601String(),
      });
    }
    
    return response;
  }
  
  /// Sign in with email and password
  Future<supabase.AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  
  // ==================== USER PROFILE ====================
  
  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    
    // Get user skills
    final skills = await getUserSkills(userId);
    response['skills'] = skills;
    
    // Get completed resources
    final completedResources = await _supabase
        .from('users')
        .select('completed_resources')
        .eq('id', userId)
        .maybeSingle();
    
    if (completedResources != null) {
      response['completedResources'] = completedResources['completed_resources'] ?? [];
    }
    
    return response;
  }
  
  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    updates['last_active'] = DateTime.now().toIso8601String();
    
    await _supabase
        .from('users')
        .update(updates)
        .eq('id', userId);
  }
  
  /// Get user skills
  Future<Map<String, double>> getUserSkills(String userId) async {
    final response = await _supabase
        .from('user_skills')
        .select()
        .eq('user_id', userId);
    
    final skills = <String, double>{};
    for (var row in response) {
      skills[row['skill_name']] = (row['rating'] as num).toDouble();
    }
    
    return skills;
  }
  
  /// Update user skills
  Future<void> updateUserSkills(String userId, Map<String, double> skills) async {
    // Delete existing skills
    await _supabase
        .from('user_skills')
        .delete()
        .eq('user_id', userId);
    
    // Insert new skills
    final skillRows = skills.entries.map((entry) => {
      'user_id': userId,
      'skill_name': entry.key,
      'rating': entry.value,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();
    
    if (skillRows.isNotEmpty) {
      await _supabase.from('user_skills').insert(skillRows);
    }
  }
  
  /// Add points to user
  Future<void> addPoints(String userId, int points) async {
    // Get current points
    final user = await _supabase
        .from('users')
        .select('points')
        .eq('id', userId)
        .single();
    
    final currentPoints = user['points'] as int? ?? 0;
    
    // Update with new points
    await _supabase
        .from('users')
        .update({'points': currentPoints + points})
        .eq('id', userId);
  }
  
  // ==================== DEBATES ====================
  
  /// Save debate
  Future<void> saveDebate(String userId, Debate debate) async {
    // Insert or update debate
    await _supabase.from('debates').upsert({
      'id': debate.id,
      'user_id': userId,
      'topic': debate.topic,
      'mode': debate.mode == DebateMode.text ? 'text' : 'voice',
      'start_time': debate.startTime.toIso8601String(),
      'end_time': debate.endTime?.toIso8601String(),
    });
    
    // Delete existing messages for this debate
    await _supabase
        .from('debate_messages')
        .delete()
        .eq('debate_id', debate.id);
    
    // Insert messages
    if (debate.messages.isNotEmpty) {
      final messageRows = debate.messages.map((msg) => {
        'debate_id': debate.id,
        'content': msg.content,
        'is_user': msg.isUser,
        'timestamp': msg.timestamp.toIso8601String(),
      }).toList();
      
      await _supabase.from('debate_messages').insert(messageRows);
    }
    
    // Save feedback if exists
    if (debate.feedback != null) {
      await _supabase.from('debate_feedback').upsert({
        'debate_id': debate.id,
        'clarity': debate.feedback!['clarity'],
        'logic': debate.feedback!['logic'],
        'rebuttal_quality': debate.feedback!['rebuttalQuality'],
        'persuasiveness': debate.feedback!['persuasiveness'],
        'communication': debate.feedback!['communication'],
      });
    }
  }
  
  /// Get debate by ID
  Future<Debate?> getDebate(String userId, String debateId) async {
    // Get debate
    final debateData = await _supabase
        .from('debates')
        .select()
        .eq('id', debateId)
        .eq('user_id', userId)
        .maybeSingle();
    
    if (debateData == null) return null;
    
    // Get messages
    final messagesData = await _supabase
        .from('debate_messages')
        .select()
        .eq('debate_id', debateId)
        .order('timestamp');
    
    final messages = messagesData.map((msg) => DebateMessage(
      content: msg['content'],
      isUser: msg['is_user'],
      timestamp: DateTime.parse(msg['timestamp']),
    )).toList();
    
    // Get feedback
    final feedbackData = await _supabase
        .from('debate_feedback')
        .select()
        .eq('debate_id', debateId)
        .maybeSingle();
    
    Map<String, double>? feedback;
    if (feedbackData != null) {
      feedback = {
        'clarity': (feedbackData['clarity'] as num?)?.toDouble() ?? 0.0,
        'logic': (feedbackData['logic'] as num?)?.toDouble() ?? 0.0,
        'rebuttalQuality': (feedbackData['rebuttal_quality'] as num?)?.toDouble() ?? 0.0,
        'persuasiveness': (feedbackData['persuasiveness'] as num?)?.toDouble() ?? 0.0,
        'communication': (feedbackData['communication'] as num?)?.toDouble() ?? 0.0,
      };
    }
    
    return Debate(
      id: debateData['id'],
      topic: debateData['topic'],
      mode: debateData['mode'] == 'text' ? DebateMode.text : DebateMode.voice,
      messages: messages,
      startTime: DateTime.parse(debateData['start_time']),
      endTime: debateData['end_time'] != null ? DateTime.parse(debateData['end_time']) : null,
      feedback: feedback,
    );
  }
  
  /// Get all debates for user
  Future<List<Debate>> getDebates(String userId) async {
    final debatesData = await _supabase
        .from('debates')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);
    
    final debates = <Debate>[];
    for (var debateData in debatesData) {
      final debate = await getDebate(userId, debateData['id']);
      if (debate != null) {
        debates.add(debate);
      }
    }
    
    return debates;
  }
  
  /// Delete debate
  Future<void> deleteDebate(String userId, String debateId) async {
    // Cascade delete will handle messages and feedback
    await _supabase
        .from('debates')
        .delete()
        .eq('id', debateId)
        .eq('user_id', userId);
  }
  
  // ==================== LEARNING RESOURCES ====================
  
  /// Get learning resources by skill
  Future<List<Map<String, dynamic>>> getResourcesBySkill(String skill) async {
    return await _supabase
        .from('learning_resources')
        .select()
        .eq('skill_category', skill)
        .order('created_at');
  }
  
  /// Mark resource as completed
  Future<void> markResourceCompleted(String userId, String resourceId) async {
    final user = await _supabase
        .from('users')
        .select('completed_resources')
        .eq('id', userId)
        .single();
    
    final completedResources = List<String>.from(user['completed_resources'] ?? []);
    if (!completedResources.contains(resourceId)) {
      completedResources.add(resourceId);
      
      await _supabase
          .from('users')
          .update({'completed_resources': completedResources})
          .eq('id', userId);
    }
  }
  
  // ==================== REALTIME SUBSCRIPTIONS ====================
  
  /// Subscribe to user changes
  supabase.RealtimeChannel subscribeToUser(String userId, void Function(Map<String, dynamic>) callback) {
    return _supabase
        .channel('user-$userId')
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: supabase.PostgresChangeFilter(type: supabase.PostgresChangeFilterType.eq, column: 'id', value: userId),
          callback: (payload) => callback(payload.newRecord),
        )
        .subscribe();
  }
}
