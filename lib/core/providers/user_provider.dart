import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final StorageService _storageService;
  bool _isLoading = true;
  String _textSize = 'M'; // S, M, L
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProvider(this._storageService) {
    _initializeUser();
    _loadTextSize();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _user!.id.isNotEmpty;
  String get textSize => _textSize;
  
  double get textSizeMultiplier {
    switch (_textSize) {
      case 'S':
        return 0.85;
      case 'L':
        return 1.15;
      default:
        return 1.0;
    }
  }

  Future<void> _loadTextSize() async {
    _textSize = await _storageService.getTextSize();
    // Don't call notifyListeners here to avoid rebuild loop
  }

  Future<void> setTextSize(String size) async {
    if (_textSize != size) {
      _textSize = size;
      await _storageService.saveTextSize(size);
      notifyListeners();
    }
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();
    
    // Check if there's a Firebase user already logged in
    final firebaseUser = _auth.currentUser;
    
    if (firebaseUser != null) {
      // User is logged in, get their data from Firestore
      await _getUserFromFirestore(firebaseUser.uid);
    } else {
      // No Firebase user, try to get from local storage
      _user = await _storageService.getUser();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _getUserFromFirestore(String uid) async {
    try {
      print('Getting user data from Firestore for uid: $uid');
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      
      if (docSnapshot.exists) {
        print('User document exists in Firestore');
        // Convert Firestore data to User model
        final userData = docSnapshot.data() as Map<String, dynamic>;
        
        try {
          // Handle Timestamp conversion safely
          DateTime createdAt;
          DateTime lastActive;
          
          if (userData['createdAt'] is Timestamp) {
            createdAt = (userData['createdAt'] as Timestamp).toDate();
          } else if (userData['createdAt'] is String) {
            createdAt = DateTime.parse(userData['createdAt']);
          } else {
            createdAt = DateTime.now();
          }
          
          if (userData['lastActive'] is Timestamp) {
            lastActive = (userData['lastActive'] as Timestamp).toDate();
          } else if (userData['lastActive'] is String) {
            lastActive = DateTime.parse(userData['lastActive']);
          } else {
            lastActive = DateTime.now();
          }
          
          // Create user object with safe conversions
          _user = User(
            id: uid,
            name: userData['name'] ?? '',
            email: userData['email'] ?? '',
            photoUrl: userData['photoUrl'],
            createdAt: createdAt,
            lastActive: lastActive,
            points: userData['points'] is int ? userData['points'] : 0,
            debatesCompleted: userData['debatesCompleted'] is int ? userData['debatesCompleted'] : 0,
            skills: userData['skills'] is Map 
                ? Map<String, double>.from(userData['skills'].map((k, v) => 
                    MapEntry(k, v is double ? v : v is int ? v.toDouble() : 0.0))) 
                : {},
            completedResources: userData['completedResources'] is List 
                ? List<String>.from(userData['completedResources']) 
                : [],
          );
          
          print('User data parsed successfully: ${_user!.name}');
          
          // Also save to local storage for offline access
          await _storageService.saveUser(_user!);
          print('User data saved to local storage');
        } catch (e) {
          print('Error parsing Firestore data: $e');
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
        print('User document does not exist in Firestore, will be created by caller');
        // Don't set _user to null, let the caller handle creation
        _user = null;
      }
    } catch (e) {
      print('Error getting user data from Firestore: $e');
      // If Firestore fails, try to get user from local storage
      _user = await _storageService.getUser();
      
      if (_user != null) {
        print('Retrieved user from local storage: ${_user!.name}');
      } else {
        print('No user found in local storage');
      }
    }
  }

  Future<void> updateUser(User user) async {
    print('=== UPDATE USER: Updating user ${user.id}');
    print('=== UPDATE USER: Points=${user.points}, Debates=${user.debatesCompleted}, Skills=${user.skills.length}');
    
    _user = user;
    
    // Update in Firestore if logged in (with timeout to avoid blocking)
    if (_auth.currentUser != null) {
      try {
        await _firestore.collection('users').doc(user.id).update({
          'name': user.name,
          'email': user.email,
          'lastActive': Timestamp.fromDate(DateTime.now()),
          'points': user.points,
          'debatesCompleted': user.debatesCompleted,
          'skills': user.skills,
          'completedResources': user.completedResources,
        }).timeout(const Duration(seconds: 2));
        print('=== UPDATE USER: Firestore update successful');
      } catch (e) {
        print('=== UPDATE USER: Firestore error (expected if DB not created): $e');
        // Continue with local storage even if Firestore fails
      }
    } else {
      print('=== UPDATE USER: No Firebase user, skipping Firestore update');
    }
    
    // Also update in local storage
    final saved = await _storageService.saveUser(user);
    print('=== UPDATE USER: Local storage save: ${saved ? "SUCCESS" : "FAILED"}');
    
    notifyListeners();
    print('=== UPDATE USER: notifyListeners() called - update complete');
  }

  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Attempting login with email: $email');
      
      // Sign in with Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Firebase Auth login successful, uid: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        // Get user data from Firestore
        await _getUserFromFirestore(userCredential.user!.uid);
        
        print('User data retrieved: ${_user != null ? 'success' : 'failed'}');
        
        // If user data wasn't found in Firestore, create it
        if (_user == null) {
          print('Creating new user data in Firestore for login');
          final now = DateTime.now();
          final firebaseUser = userCredential.user!;
          
          _user = User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? email.split('@')[0],
            email: email,
            createdAt: now,
            lastActive: now,
            points: 0,
            skills: {},
            completedResources: [],
          );
          
          // Save to Firestore
          try {
            await _firestore.collection('users').doc(_user!.id).set({
              'name': _user!.name,
              'email': _user!.email,
              'createdAt': Timestamp.fromDate(_user!.createdAt),
              'lastActive': Timestamp.fromDate(_user!.lastActive),
              'points': _user!.points,
              'debatesCompleted': _user!.debatesCompleted,
              'skills': _user!.skills,
              'completedResources': _user!.completedResources,
              'photoUrl': _user!.photoUrl,
              'preferences': {
                'darkMode': false,
                'notificationsEnabled': true,
                'voiceSpeed': 1.0,
                'voicePitch': 1.0,
              },
            });
            print('New user data saved to Firestore');
          } catch (e) {
            print('Error saving new user to Firestore: $e');
          }
          
          // Save to local storage
          await _storageService.saveUser(_user!);
        }
        
        // Update last active timestamp
        if (_user != null) {
          try {
            await _firestore.collection('users').doc(_user!.id).update({
              'lastActive': Timestamp.fromDate(DateTime.now()),
            });
            print('Last active timestamp updated');
            
            // Sync any local data with Firestore
            await _storageService.syncWithFirestore();
            print('Data synchronized with Firestore after login');
          } catch (e) {
            print('Error updating last active timestamp: $e');
          }
        }
      }
      
      _isLoading = false;
      notifyListeners();
      print('Login process completed, isLoggedIn: $isLoggedIn');
      return null; // Success
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      
      if (e.code == 'user-not-found') {
        return 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password';
      } else {
        return e.message;
      }
    } catch (e, stackTrace) {
      print('General login error: $e');
      print('Stack trace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      
      // Check if user is actually logged in despite the error
      if (_auth.currentUser != null) {
        print('Firebase user exists despite error, attempting to continue...');
        final firebaseUser = _auth.currentUser!;
        
        try {
          await _getUserFromFirestore(firebaseUser.uid);
          
          // If user document doesn't exist, create it
          if (_user == null) {
            print('Creating user document after error recovery...');
            final now = DateTime.now();
            
            _user = User(
              id: firebaseUser.uid,
              name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
              email: firebaseUser.email ?? '',
              createdAt: now,
              lastActive: now,
              points: 0,
              skills: {},
              completedResources: [],
            );
            
            // Save to Firestore
            try {
              await _firestore.collection('users').doc(_user!.id).set({
                'name': _user!.name,
                'email': _user!.email,
                'createdAt': Timestamp.fromDate(_user!.createdAt),
                'lastActive': Timestamp.fromDate(_user!.lastActive),
                'points': _user!.points,
                'debatesCompleted': _user!.debatesCompleted,
                'skills': _user!.skills,
                'completedResources': _user!.completedResources,
                'photoUrl': _user!.photoUrl,
                'preferences': {
                  'darkMode': false,
                  'notificationsEnabled': true,
                  'voiceSpeed': 1.0,
                  'voicePitch': 1.0,
                },
              });
              print('User document created successfully');
            } catch (firestoreError) {
              print('Error creating user document: $firestoreError');
            }
            
            // Save to local storage
            await _storageService.saveUser(_user!);
          }
          
          if (_user != null) {
            print('Successfully recovered user data, login OK');
            _isLoading = false;
            notifyListeners();
            return null; // Success
          }
        } catch (e2) {
          print('Failed to retrieve/create user data: $e2');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return 'An error occurred during login. Please try again.';
    }
  }

  Future<String?> signup(String name, String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Attempting signup with email: $email, name: $name');
      
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Firebase Auth signup successful, uid: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        // Create user data locally
        final now = DateTime.now();
        _user = User(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          createdAt: now,
          lastActive: now,
          points: 0,
          skills: {},
          completedResources: [],
        );
        
        // Save to local storage (Firestore disabled)
        await _storageService.saveUser(_user!);
        print('User saved to local storage');
      }
      
      _isLoading = false;
      notifyListeners();
      print('Signup process completed, isLoggedIn: $isLoggedIn');
      return null; // Success
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during signup: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      
      if (e.code == 'email-already-in-use') {
        return 'This email is already registered';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak';
      } else {
        return e.message;
      }
    } catch (e, stackTrace) {
      print('General signup error: $e');
      print('Stack trace: $stackTrace');
      
      // Check if user was created despite error
      if (_auth.currentUser != null) {
        print('User exists in Firebase Auth despite error, creating local profile...');
        final firebaseUser = _auth.currentUser!;
        final now = DateTime.now();
        
        _user = User(
          id: firebaseUser.uid,
          name: name,
          email: email,
          createdAt: now,
          lastActive: now,
          points: 0,
          skills: {},
          completedResources: [],
        );
        
        await _storageService.saveUser(_user!);
        print('User profile created locally after error recovery');
        
        _isLoading = false;
        notifyListeners();
        return null; // Success after recovery
      }
      
      _isLoading = false;
      notifyListeners();
      return 'An error occurred: $e';
    }
  }

  Future<void> logout() async {
    try {
      print('=== LOGOUT START ===');
      _isLoading = true;
      notifyListeners();
      
      // Update last active time in Firestore before signing out
      if (_user != null) {
        try {
          await _firestore.collection('users').doc(_user!.id).update({
            'lastActive': Timestamp.fromDate(DateTime.now()),
          }).timeout(const Duration(seconds: 3));
          print('Last active timestamp updated before logout');
          
          // Make sure all data is synced before signing out
          await _storageService.syncWithFirestore().timeout(const Duration(seconds: 3));
          print('Final data sync completed before logout');
        } catch (e) {
          print('Error updating data before logout: $e - continuing anyway');
          // Don't let Firestore errors block logout
        }
      }
      
      // Sign out from Firebase Auth
      try {
        await _auth.signOut();
        print('Firebase signOut completed');
      } catch (e) {
        print('Error signing out from Firebase: $e');
      }
      
      _user = null;
      print('User set to null, isLoggedIn: $isLoggedIn');
      
      // Clear local storage
      try {
        await _storageService.clearUser();
        print('Local storage cleared');
      } catch (e) {
        print('Error clearing local storage: $e');
      }
      
      _isLoading = false;
      notifyListeners();
      print('=== LOGOUT COMPLETE, notifyListeners called ===');
    } catch (e) {
      print('Error during logout: $e');
      // Even if there's an error, still try to clear user state
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSkills(Map<String, double> skills) async {
    if (_user != null) {
      print('=== UPDATE SKILLS: Updating with ${skills.length} skills');
      skills.forEach((key, value) {
        print('  - $key: ${(value * 100).toStringAsFixed(1)}%');
      });
      
      final updatedUser = _user!.copyWith(skills: skills);
      await updateUser(updatedUser);
      
      print('=== UPDATE SKILLS: User now has ${_user!.skills.length} skills');
      print('=== UPDATE SKILLS: Points=${_user!.points}, Debates=${_user!.debatesCompleted}');
    } else {
      print('=== UPDATE SKILLS: ERROR - User is null!');
    }
  }

  Future<void> addPoints(int points) async {
    if (_user != null) {
      print('=== ADD POINTS: Adding $points points (current: ${_user!.points})');
      final updatedPoints = _user!.points + points;
      final updatedUser = _user!.copyWith(points: updatedPoints);
      await updateUser(updatedUser);
      print('=== ADD POINTS: New points total: ${_user!.points}');
    } else {
      print('=== ADD POINTS: ERROR - User is null!');
    }
  }

  Future<void> incrementDebatesCompleted() async {
    if (_user != null) {
      print('=== INCREMENT DEBATES: Current count: ${_user!.debatesCompleted}');
      final updatedCount = _user!.debatesCompleted + 1;
      print('=== INCREMENT DEBATES: New count: $updatedCount');
      final updatedUser = _user!.copyWith(debatesCompleted: updatedCount);
      await updateUser(updatedUser);
      print('=== INCREMENT DEBATES: Update complete, current user count: ${_user!.debatesCompleted}');
    } else {
      print('=== INCREMENT DEBATES: ERROR - User is null!');
    }
  }

  Future<void> refreshUser() async {
    if (_user != null) {
      print('=== REFRESH USER: Reloading from storage...');
      final user = await _storageService.getUser();
      if (user != null) {
        _user = user;
        print('=== REFRESH USER: Points=${user.points}, Debates=${user.debatesCompleted}');
        notifyListeners();
      }
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

  Future<void> updateProfilePhoto(String photoPath) async {
    if (_user != null) {
      try {
        // Since we're not using Firebase Storage, we'll store the local path
        // In a production app, you'd upload to Firebase Storage and get a URL
        final updatedUser = _user!.copyWith(photoUrl: photoPath);
        await updateUser(updatedUser);
        print('Profile photo updated: $photoPath');
      } catch (e) {
        print('Error updating profile photo: $e');
        rethrow;
      }
    }
  }

  Future<void> removeProfilePhoto() async {
    if (_user != null) {
      try {
        final updatedUser = _user!.copyWith(photoUrl: null);
        await updateUser(updatedUser);
        print('Profile photo removed');
      } catch (e) {
        print('Error removing profile photo: $e');
        rethrow;
      }
    }
  }
}

