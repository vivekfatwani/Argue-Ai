import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final StorageService _storageService;
  bool _isLoading = true;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Auth uses Firebase, but data storage is local only
  static const bool _useFirestore = false; // Keep false for local-only storage

  UserProvider(this._storageService) {
    _initializeUser();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _user!.id.isNotEmpty;

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();
    
    // Check if there's a Firebase user already logged in (authentication only)
    final firebaseUser = _auth.currentUser;
    
    if (firebaseUser != null) {
      // User is authenticated, load their data from local storage
      _user = await _storageService.getUser();
      
      if (_user != null) {
        print('Retrieved user from local storage: ${_user!.name}');
      } else {
        // User authenticated but no local data - shouldn't happen normally
        // Create a basic profile from Firebase Auth data
        print('Creating local profile for authenticated user');
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
        await _storageService.saveUser(_user!);
      }
    } else {
      // No authenticated user
      _user = null;
      print('No authenticated user');
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
    _user = user;
    
    // Update in Firestore if logged in (only if enabled)
    if (_auth.currentUser != null && _useFirestore) {
      try {
        await _firestore.collection('users').doc(user.id).update({
          'name': user.name,
          'email': user.email,
          'lastActive': Timestamp.fromDate(DateTime.now()),
          'points': user.points,
          'skills': user.skills,
          'completedResources': user.completedResources,
        });
      } catch (e) {
        print('Error updating user in Firestore: $e');
        // Continue with local storage even if Firestore fails
      }
    }
    
    // Always update in local storage
    await _storageService.saveUser(user);
    print('User updated in local storage');
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Attempting login with email: $email');
      
      // Sign in with Firebase Auth (authentication only)
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Firebase Auth login successful, uid: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        // Try to get from local storage first
        _user = await _storageService.getUser();
        
        print('User data retrieved from local storage: ${_user != null ? 'success' : 'not found'}');
        
        // If no local data exists, create new user profile locally
        if (_user == null) {
          print('Creating new local user profile');
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
          
          // Save to local storage only
          await _storageService.saveUser(_user!);
          print('User profile saved to local storage');
        } else {
          // Update last active time in local storage
          final updatedUser = _user!.copyWith(lastActive: DateTime.now());
          await _storageService.saveUser(updatedUser);
          _user = updatedUser;
          print('Last active timestamp updated in local storage');
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
      
      // Update last active time in Firestore before signing out (only if enabled)
      if (_user != null && _useFirestore) {
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
