import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart' hide Environment;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/environment.dart';
import '../utils/exceptions.dart';


@singleton
class AuthService {
  // Lazily initialize to avoid touching Firebase when disabled
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get _enabled => Environment.useFirebase;
  void _ensureEnabled() {
    if (!_enabled) {
  throw const AuthException('Authentication is disabled in mock mode');
    }
  }

  User? get currentUser => _enabled ? _auth.currentUser : null;
  Stream<User?> get authStateChanges =>
      _enabled ? _auth.authStateChanges() : const Stream<User?>.empty();

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    _ensureEnabled();
    try {
      // Prefer native Google account picker on Android/iOS to avoid browser
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
        final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
        // Ensure previous sessions don't auto-select without UI
        await googleSignIn.signOut();
        final account = await googleSignIn.signIn();
        if (account == null) {
          throw const AuthException('Sign-in was cancelled');
        }
        final auth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: auth.idToken,
          accessToken: auth.accessToken,
        );
        final userCred = await _auth.signInWithCredential(credential);
        await _upsertUserProfile(userCred.user);
        return userCred;
      }

      // Fallback to provider flow (web/desktop)
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});
      final userCred = await _auth.signInWithProvider(provider);
      await _upsertUserProfile(userCred.user);
      return userCred;
    } on FirebaseAuthException catch (e) {
      // Provide clearer messages and guidance
      final msg = _friendlyAuthMessage(e);
  throw AuthException(msg);
    } catch (e) {
      throw AuthException('Google sign in failed: ${e.toString()}');
    }
  }

  // Link current account with Google provider
  Future<UserCredential> linkWithGoogle() async {
    _ensureEnabled();
    try {
      final current = _auth.currentUser;
  if (current == null) throw const AuthException('No authenticated user');
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
        final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
        await googleSignIn.signOut();
        final account = await googleSignIn.signIn();
        if (account == null) {
          throw const AuthException('Linking was cancelled');
        }
        final auth = await account.authentication;
        final cred = GoogleAuthProvider.credential(
          idToken: auth.idToken,
          accessToken: auth.accessToken,
        );
        final linked = await current.linkWithCredential(cred);
        await _upsertUserProfile(linked.user);
        return linked;
      }
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});
      final linked = await current.linkWithProvider(provider);
      await _upsertUserProfile(linked.user);
      return linked;
    } on FirebaseAuthException catch (e) {
  throw AuthException(_friendlyAuthMessage(e));
    } catch (e) {
      throw AuthException('Failed to link Google: ${e.toString()}');
    }
  }

  // Facebook Sign In
  Future<UserCredential> signInWithFacebook() async {
    _ensureEnabled();
    // If the Facebook plugin is not included or not configured, fail fast with a friendly message
  throw const AuthException('Facebook sign-in is not configured on this build');
  }

  // Email & Password Authentication
  Future<List<String>> _fetchSignInMethods(String email) async {
    try {
      return await _auth.fetchSignInMethodsForEmail(email);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _ensureEnabled();
    try {
      // If this email is already registered with any provider, guide the user
      final methods = await _fetchSignInMethods(email);
      if (methods.isNotEmpty) {
        if (methods.contains('password')) {
          throw const AuthException('Email already in use. Sign in or reset your password.');
        }
        if (methods.contains('google.com')) {
          throw const AuthException('This email is registered with Google. Use Continue with Google to sign in.');
        }
        throw const AuthException('Email already in use with another sign-in method.');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Try to send verification email but don't fail sign-up if it errors
      try {
        await credential.user?.sendEmailVerification();
      } catch (_) {
        // Non-fatal: user can request resend from UI
      }
      await _upsertUserProfile(credential.user);
      return credential;
    } on FirebaseAuthException catch (e) {
    throw AuthException(_friendlyAuthMessage(e, email: email));
    } catch (e) {
  // Bubble a clearer error for diagnostics without exposing internals
  throw const AuthException('Sign up failed. Please try again.');
    }
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _ensureEnabled();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Ensure email verification state is up to date
      await cred.user?.reload();
      if (cred.user != null && !(cred.user!.emailVerified)) {
        // Keep the session but inform caller to verify email
        // UI will show a verification dialog and allow recheck
        await _upsertUserProfile(cred.user);
        return cred;
      }
      await _upsertUserProfile(cred.user);
      return cred;
    } on FirebaseAuthException catch (e) {
      // Provide tailored guidance based on known providers
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-login-credentials') {
        final methods = await _fetchSignInMethods(email);
        if (methods.contains('google.com') && !methods.contains('password')) {
          throw const AuthException('This email is registered with Google. Use Continue with Google.');
        }
        if (methods.contains('password')) {
          if (e.code == 'wrong-password' || e.code == 'invalid-login-credentials') {
            throw const AuthException('Incorrect password. Use Forgot Password to reset.');
          }
        }
      }
      throw AuthException(_friendlyAuthMessage(e, email: email));
    } catch (e) {
  throw const AuthException('Sign in failed. Please try again.');
    }
  }

  // Link current user with email/password
  Future<UserCredential> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    _ensureEnabled();
    try {
      final current = _auth.currentUser;
  if (current == null) throw const AuthException('No authenticated user');
      final cred = EmailAuthProvider.credential(email: email, password: password);
      final result = await current.linkWithCredential(cred);
      await _upsertUserProfile(result.user);
      return result;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthMessage(e, email: email));
    } catch (e) {
      throw const AuthException('Failed to link email/password');
    }
  }

  Future<void> _upsertUserProfile(User? user) async {
    if (user == null) return;
    try {
      final db = FirebaseFirestore.instance;
      final docRef = db.collection('users').doc(user.uid);
      final snap = await docRef.get();
      final now = Timestamp.now();

      // Minimal default values required by UserModel
      final defaultProfile = <String, dynamic>{
        'id': user.uid,
        'email': user.email,
        'name': user.displayName ?? (user.email?.split('@').first ?? 'User'),
        'bio': null,
        'birthDate': Timestamp.fromDate(DateTime(2000, 1, 1)),
        'profileImageUrl': user.photoURL,
        'interests': <String>[],
        'personalityType': null,
        'location': null,
        'photos': <String>[],
        'privacySettings': {
          'showAge': true,
          'showLocation': true,
          'showOnlineStatus': true,
          'allowMessagesFromMatches': true,
          'allowLocationSharing': false,
          'maxDistance': 50.0,
        },
        'profileCompletion': {
          'hasProfilePhoto': user.photoURL != null,
          'hasBio': false,
          'hasInterests': false,
          'hasPersonalityTest': false,
          'hasLocation': false,
          'hasMultiplePhotos': false,
          'isEmailVerified': user.emailVerified,
          'hasPhoneNumber': false,
        },
        'preferences': null,
        'createdAt': now,
        'updatedAt': now,
        'isOnline': false,
        'lastSeen': null,
        'isVerified': user.emailVerified,
        'isDiscoverable': true,
      };

      if (!snap.exists) {
        await docRef.set(defaultProfile, SetOptions(merge: true));
        return;
      }

      // For existing docs, top up any missing required fields without overwriting user data
      final data = snap.data() as Map<String, dynamic>;
      final Map<String, dynamic> updates = {'updatedAt': now};

      void ensure(String key, dynamic value) {
        if (!data.containsKey(key) || data[key] == null) {
          updates[key] = value;
        }
      }

      ensure('email', defaultProfile['email']);
      ensure('name', defaultProfile['name']);
      ensure('birthDate', defaultProfile['birthDate']);
      ensure('interests', defaultProfile['interests']);
      ensure('photos', defaultProfile['photos']);
      ensure('privacySettings', defaultProfile['privacySettings']);
      ensure('profileCompletion', defaultProfile['profileCompletion']);
      ensure('createdAt', defaultProfile['createdAt']);
      ensure('isOnline', defaultProfile['isOnline']);
      ensure('lastSeen', defaultProfile['lastSeen']);
      ensure('isVerified', defaultProfile['isVerified']);
      ensure('isDiscoverable', defaultProfile['isDiscoverable']);

      if (updates.isNotEmpty) {
        await docRef.set(updates, SetOptions(merge: true));
      }
    } catch (_) {
      // Silently ignore; rules may block writes. UI will still work if reads are allowed.
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    _ensureEnabled();
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
  throw AuthException(e.message ?? 'Password reset failed');
    } catch (e) {
  throw const AuthException('An unexpected error occurred');
    }
  }

  // Email Verification
  Future<void> sendEmailVerification() async {
    _ensureEnabled();
    try {
      await currentUser?.sendEmailVerification();
    } catch (e) {
      throw const AuthException('Failed to send verification email');
    }
  }

  Future<void> reloadUser() async {
    _ensureEnabled();
    try {
      await currentUser?.reload();
    } catch (e) {
      throw const AuthException('Failed to reload user');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _ensureEnabled();
    try {
  await _auth.signOut();
    } catch (e) {
      throw const AuthException('Sign out failed');
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    _ensureEnabled();
    try {
      await currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
  throw const AuthException('Please re-authenticate to delete your account');
      }
  throw AuthException(e.message ?? 'Account deletion failed');
    } catch (e) {
  throw const AuthException('An unexpected error occurred');
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    _ensureEnabled();
    try {
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
  throw const AuthException('Please re-authenticate to change your password');
      }
  throw AuthException(e.message ?? 'Password update failed');
    } catch (e) {
  throw const AuthException('An unexpected error occurred');
    }
  }

  // Update Email
  Future<void> updateEmail(String newEmail) async {
    _ensureEnabled();
    try {
      await currentUser?.updateEmail(newEmail);
      await sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
  throw const AuthException('Please re-authenticate to change your email');
      }
  throw AuthException(e.message ?? 'Email update failed');
    } catch (e) {
  throw const AuthException('An unexpected error occurred');
    }
  }

  String _friendlyAuthMessage(FirebaseAuthException e, {String? email}) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already in use. Sign in instead or link this email to your current account.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled for this project. Enable it in Firebase Console > Authentication > Sign-in method.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Sign-in was cancelled.';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}

// Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (user) => user);
});
