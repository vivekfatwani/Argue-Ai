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

  UserProvider(this._storageService) {
    _initializeUser();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null && _user!.id.isNotEmpty;

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
    
    // Update in Firestore if logged in
    if (_auth.currentUser != null) {
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
    
    // Also update in local storage
    await _storageService.saveUser(user);
    notifyListeners();
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
        // Create user data in Firestore
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
        
        // Save to Firestore
        try {
          print('Creating user document in Firestore');
          await _firestore.collection('users').doc(_user!.id).set({
            'name': _user!.name,
            'email': _user!.email,
            'createdAt': Timestamp.fromDate(_user!.createdAt),
            'lastActive': Timestamp.fromDate(_user!.lastActive),
            'points': _user!.points,
            'skills': _user!.skills,
            'completedResources': _user!.completedResources,
            'preferences': {
              'darkMode': false,
              'notificationsEnabled': true,
              'voiceSpeed': 1.0,
              'voicePitch': 1.0,
            },
          });
          print('User document created successfully in Firestore');
          
          // Initialize collections for debates and resources
          // This ensures the collections exist even if empty
          await _firestore.collection('users').doc(_user!.id).collection('debates').doc('placeholder').set({
            'isPlaceholder': true,
            'createdAt': Timestamp.fromDate(now)
          });
          await _firestore.collection('users').doc(_user!.id).collection('resources').doc('placeholder').set({
            'isPlaceholder': true,
            'createdAt': Timestamp.fromDate(now)
          });
          print('Initialized subcollections in Firestore');
        } catch (e) {
          print('Error creating user document in Firestore: $e');
          // Continue even if Firestore fails
        }
        
        // Save to local storage
        await _storageService.saveUser(_user!);
        print('User saved to local storage');
        
        // Sync any existing local data with Firestore
        await _storageService.syncWithFirestore();
        print('Local data synchronized with Firestore after signup');
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
    } catch (e) {
      print('General signup error: $e');
      _isLoading = false;
      notifyListeners();
      return 'An error occurred: $e';
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Update last active time in Firestore before signing out
      if (_user != null) {
        try {
          await _firestore.collection('users').doc(_user!.id).update({
            'lastActive': Timestamp.fromDate(DateTime.now()),
          });
          print('Last active timestamp updated before logout');
          
          // Make sure all data is synced before signing out
          await _storageService.syncWithFirestore();
          print('Final data sync completed before logout');
        } catch (e) {
          print('Error updating data before logout: $e');
        }
      }
      
      await _auth.signOut();
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
