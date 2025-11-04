import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final StorageService _storageService;
  final SupabaseService _supabaseService;
  bool _isLoading = true;

  UserProvider(this._storageService, this._supabaseService) {
    _initializeUser();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _user!.id.isNotEmpty;

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();
    
    // Check if there's a Supabase user already logged in
    final currentUser = _supabaseService.currentUser;
    
    if (currentUser != null) {
      // User is logged in, get their data from Supabase
      await _getUserFromSupabase(currentUser.id);
    } else {
      // No Supabase user, try to get from local storage
      _user = await _storageService.getUser();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _getUserFromSupabase(String uid) async {
    try {
      print('Getting user data from Supabase for uid: $uid');
      final userData = await _supabaseService.getUserProfile(uid);
      
      if (userData != null) {
        print('User profile exists in Supabase');
        
        try {
          // Parse dates safely
          DateTime createdAt;
          DateTime lastActive;
          
          if (userData['created_at'] is String) {
            createdAt = DateTime.parse(userData['created_at']);
          } else {
            createdAt = DateTime.now();
          }
          
          if (userData['last_active'] is String) {
            lastActive = DateTime.parse(userData['last_active']);
          } else {
            lastActive = DateTime.now();
          }
          
          // Get skills from the separate table
          final skills = await _supabaseService.getUserSkills(uid);
          
          // Create user object with safe conversions
          _user = User(
            id: uid,
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            photoUrl: userData['photo_url'],
            createdAt: createdAt,
            lastActive: lastActive,
            points: userData['points'] is int ? userData['points'] : 0,
            skills: skills,
            completedResources: userData['completed_resources'] is List 
                ? List<String>.from(userData['completed_resources']) 
                : [],
          );
          
          print('User data parsed successfully: ${_user!.name}');
          
          // Also save to local storage for offline access
          await _storageService.saveUser(_user!);
          print('User data saved to local storage');
        } catch (e) {
          print('Error parsing Supabase data: $e');
          // Create a basic user object if parsing fails
          _user = User(
            id: uid,
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          );
          await _storageService.saveUser(_user!);
        }
      } else {
        print('User profile does not exist in Supabase, will be created by caller');
        _user = null;
      }
    } catch (e) {
      print('Error getting user data from Supabase: $e');
      // If Supabase fails, try to get user from local storage
      _user = await _storageService.getUser();
      
      if (_user != null) {
        print('Retrieved user from local storage: ${_user!.name}');
      } else {
        print('No user found in local storage');
      }
    }
  }

  Future<void> updateUser(User user) async {
    _user = user;
    
    // Update in Supabase if logged in
    if (_supabaseService.currentUser != null) {
      try {
        await _supabaseService.updateUserProfile(user.id, {
          'name': user.name,
          'email': user.email,
          'last_active': DateTime.now().toIso8601String(),
          'points': user.points,
          'completed_resources': user.completedResources,
          'photo_url': user.photoUrl,
        });
        
        // Update skills separately
        if (user.skills.isNotEmpty) {
          await _supabaseService.updateUserSkills(user.id, user.skills);
        }
      } catch (e) {
        print('Error updating user in Supabase: $e');
        // Continue with local storage even if Supabase fails
      }
    }
    
    // Also update in local storage
    await _storageService.saveUser(user);
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Attempting login with email: $email');
      
      // Sign in with Supabase
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        print('Supabase Auth login failed: No user returned');
        _isLoading = false;
        notifyListeners();
        return 'Login failed. Please check your credentials.';
      }
      
      final userId = response.user!.id;
      print('Supabase Auth login successful, uid: $userId');
      
      // Get user data from Supabase
      await _getUserFromSupabase(userId);
      
      print('User data retrieved: ${_user != null ? 'success' : 'failed'}');
      
      // If user profile wasn't found in Supabase, create it
      if (_user == null) {
        print('Creating new user profile in Supabase for login');
        final now = DateTime.now();
        
        _user = User(
          id: userId,
          name: email.split('@')[0],
          email: email,
          createdAt: now,
          lastActive: now,
          points: 0,
          skills: {},
          completedResources: [],
        );
        
        // Save to Supabase
        try {
          await _supabaseService.updateUserProfile(userId, {
            'name': _user!.name,
            'email': _user!.email,
            'created_at': _user!.createdAt.toIso8601String(),
            'last_active': _user!.lastActive.toIso8601String(),
            'points': _user!.points,
            'completed_resources': _user!.completedResources,
          });
          print('New user profile saved to Supabase');
        } catch (e) {
          print('Error saving new user to Supabase: $e');
        }
        
        // Save to local storage
        await _storageService.saveUser(_user!);
      }
      
      // Update last active timestamp
      if (_user != null) {
        try {
          await _supabaseService.updateUserProfile(_user!.id, {
            'last_active': DateTime.now().toIso8601String(),
          });
          print('Last active timestamp updated');
        } catch (e) {
          print('Error updating last active timestamp: $e');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      print('Login process completed, isLoggedIn: $isLoggedIn');
      return null; // Success
    } catch (e, stackTrace) {
      print('General login error: $e');
      print('Stack trace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      
      // Check if it's an authentication error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('invalid login credentials')) {
        return 'Invalid email or password';
      } else if (errorMessage.contains('email not confirmed')) {
        return 'Please verify your email before logging in';
      }
      
      return 'An error occurred during login. Please try again.';
    }
  }

  Future<String?> signup(String name, String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Attempting signup with email: $email, name: $name');
      
      // Create user in Supabase Auth and database
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        name: name,
      );
      
      if (response.user == null) {
        print('Supabase Auth signup failed: No user returned');
        _isLoading = false;
        notifyListeners();
        return 'Signup failed. Please try again.';
      }
      
      print('Supabase Auth signup successful, uid: ${response.user!.id}');
      
      // Create user object
      final now = DateTime.now();
      _user = User(
        id: response.user!.id,
        name: name,
        email: email,
        createdAt: now,
        lastActive: now,
        points: 0,
        skills: {},
        completedResources: [],
      );
      
      // Note: User profile is already created in SupabaseService.signUp()
      // Just save to local storage
      await _storageService.saveUser(_user!);
      print('User saved to local storage');
      
      _isLoading = false;
      notifyListeners();
      print('Signup process completed, isLoggedIn: $isLoggedIn');
      return null; // Success
    } catch (e) {
      print('General signup error: $e');
      _isLoading = false;
      notifyListeners();
      
      // Check for common signup errors
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('user already registered')) {
        return 'This email is already registered';
      } else if (errorMessage.contains('password')) {
        return 'Password is too weak';
      }
      
      return 'An error occurred: $e';
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Update last active time in Supabase before signing out
      if (_user != null) {
        try {
          await _supabaseService.updateUserProfile(_user!.id, {
            'last_active': DateTime.now().toIso8601String(),
          });
          print('Last active timestamp updated before logout');
        } catch (e) {
          print('Error updating data before logout: $e');
        }
      }
      
      await _supabaseService.signOut();
      _user = null;
      await _storageService.clearUser();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSkills(Map<String, double> skills) async {
    if (_user != null) {
      final updatedUser = _user!.copyWith(skills: skills);
      await updateUser(updatedUser);
    }
  }

  Future<void> addPoints(int points) async {
    if (_user != null) {
      final updatedPoints = _user!.points + points;
      final updatedUser = _user!.copyWith(points: updatedPoints);
      await updateUser(updatedUser);
    }
  }

  Future<void> markResourceCompleted(String resourceId) async {
    if (_user != null) {
      final completedResources = List<String>.from(_user!.completedResources);
      if (!completedResources.contains(resourceId)) {
        completedResources.add(resourceId);
        final updatedUser = _user!.copyWith(completedResources: completedResources);
        await updateUser(updatedUser);
      }
    }
  }
}
