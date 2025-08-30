import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'user_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email & Password Sign Up
  static Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await _createUserProfile(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Email & Password Sign In
  static Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Handle Firebase Auth Errors
  static String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return error.toString();
  }

  // Random emoji avatars for new users
  static const List<String> _emojiAvatars = [
    '🐱',
    '🐶',
    '🐼',
    '🦊',
    '🐨',
    '🐯',
    '🦁',
    '🐸',
    '🐧',
    '🦉',
    '🦄',
    '🐺',
    '🐰',
    '🦝',
    '🐮',
    '🐷',
    '🐻',
    '🐙',
    '🦋',
    '🐝',
    '🌟',
    '⭐',
    '🌙',
    '☀️',
    '🌈',
    '🔥',
    '⚡',
    '💎',
    '🎯',
    '🎨',
    '🚀',
    '🎸',
    '🎮',
    '📚',
    '🧠',
    '💡',
    '🏆',
    '🎭',
    '🎪',
    '🎊',
  ];

  // Custom exceptions for auth service
  static const String _signInFailedError = 'Sign in failed';
  static const String _signOutFailedError = 'Sign out failed';
  static const String _userCancelledError = 'User cancelled sign in';
  static const String _networkError = 'Network error occurred';
  static const String _accountDisabledError = 'Account has been disabled';
  static const String _profileCreationError = 'Failed to create user profile';

  /// Get current user stream for real-time authentication state changes
  static Stream<User?> get currentUserStream {
    return _auth.authStateChanges();
  }

  /// Get current user
  static User? get currentUser {
    return _auth.currentUser;
  }

  /// Check if user is currently signed in
  static bool get isSignedIn {
    return currentUser != null;
  }

  /// Get current user ID
  static String? get currentUserId {
    return currentUser?.uid;
  }

  /// Sign in with Google
  static Future<UserCredential> signInWithGoogle() async {
    try {
      // Start token refresh service
      TokenService.startTokenRefresh();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception(_userCancelledError);
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check if this is a new user and create profile if needed
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserProfile(userCredential.user!);
      } else {
        // For existing users, check if profile exists in Firestore
        await _ensureUserProfileExists(userCredential.user!);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e.toString().contains(_userCancelledError)) {
        rethrow;
      }
      throw Exception('$_signInFailedError: ${e.toString()}');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      // Stop token refresh
      TokenService.stopTokenRefresh();

      // Sign out from both Google and Firebase
      await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
    } catch (e) {
      throw Exception('$_signOutFailedError: ${e.toString()}');
    }
  }

  /// Delete current user account
  static Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Delete user profile from Firestore first
      await UserService.deleteUserProfile(user.uid);

      // Delete the Firebase Auth user
      await user.delete();

      // Sign out from Google
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Reauthenticate user with Google (required for sensitive operations)
  static Future<void> reauthenticateWithGoogle() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception(_userCancelledError);
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      throw Exception('Reauthentication failed: ${e.toString()}');
    }
  }

  /// Get current user profile from Firestore
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      return await UserService.getUserProfile(user.uid);
    } catch (e) {
      // Return null if profile doesn't exist rather than throwing
      return null;
    }
  }

  /// Get current user profile stream from Firestore
  static Stream<UserModel?> getCurrentUserProfileStream() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return UserService.getUserProfileStream(user.uid);
  }

  /// Refresh current user token
  static Future<void> refreshUserToken() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.getIdToken(true); // Force refresh
    } catch (e) {
      throw Exception('Failed to refresh user token: ${e.toString()}');
    }
  }

  /// Create user profile in Firestore for new users
  static Future<void> _createUserProfile(User user) async {
    try {
      final randomAvatar = _getRandomEmojiAvatar();

      await UserService.createUserProfile(
        userId: user.uid,
        name: user.displayName ?? 'Anonymous User',
        email: user.email ?? '',
        avatar: randomAvatar,
      );
    } catch (e) {
      throw Exception('$_profileCreationError: ${e.toString()}');
    }
  }

  /// Ensure user profile exists in Firestore (for existing users)
  static Future<void> _ensureUserProfileExists(User user) async {
    try {
      final profileExists = await UserService.userExists(user.uid);

      if (!profileExists) {
        // Profile doesn't exist, create it
        await _createUserProfile(user);
      } else {
        // Profile exists, update last login timestamp
        await UserService.updateUserProfile(user.uid, {
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log error but don't throw to avoid blocking sign in
      print('Warning: Failed to ensure user profile exists: ${e.toString()}');
    }
  }

  /// Get random emoji avatar
  static String _getRandomEmojiAvatar() {
    final random = Random();
    return _emojiAvatars[random.nextInt(_emojiAvatars.length)];
  }

  /// Handle Firebase Auth exceptions
  static Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return Exception(
          'An account already exists with a different sign-in method',
        );
      case 'invalid-credential':
        return Exception('The credential is invalid or has expired');
      case 'operation-not-allowed':
        return Exception('Google sign-in is not enabled');
      case 'user-disabled':
        return Exception(_accountDisabledError);
      case 'user-not-found':
        return Exception('No user found with this account');
      case 'wrong-password':
        return Exception('Wrong password provided');
      case 'network-request-failed':
        return Exception(_networkError);
      case 'too-many-requests':
        return Exception('Too many requests. Please try again later');
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return Exception(_userCancelledError);
      default:
        return Exception('Authentication error: ${e.message ?? e.code}');
    }
  }

  /// Update user display name and sync with Firestore
  static Future<void> updateDisplayName(String displayName) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(displayName);

      // Update Firestore profile
      await UserService.updateUserFields(user.uid, name: displayName);
    } catch (e) {
      throw Exception('Failed to update display name: ${e.toString()}');
    }
  }

  /// Update user email and sync with Firestore
  static Future<void> updateEmail(String email) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Update Firebase Auth email (requires recent authentication)
      await user.updateEmail(email);

      // Update Firestore profile
      await UserService.updateUserFields(user.uid, email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please reauthenticate to update email');
      }
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  /// Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send email verification: ${e.toString()}');
    }
  }

  /// Check if current user's email is verified
  static bool get isEmailVerified {
    return currentUser?.emailVerified ?? false;
  }

  /// Reload current user data
  static Future<void> reloadUser() async {
    try {
      final user = currentUser;
      if (user == null) return;

      await user.reload();
    } catch (e) {
      throw Exception('Failed to reload user: ${e.toString()}');
    }
  }

  /// Initialize auth service (call this in main.dart)
  static Future<void> initialize() async {
    try {
      // Configure Google Sign-In
      await _googleSignIn.signInSilently();

      // Listen to auth state changes and ensure profile exists
      currentUserStream.listen((User? user) async {
        if (user != null) {
          await _ensureUserProfileExists(user);
        }
      });
    } catch (e) {
      print('Warning: Failed to initialize auth service: ${e.toString()}');
    }
  }
}
