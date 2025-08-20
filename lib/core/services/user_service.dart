import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../utils/constants.dart';
import '../utils/exceptions.dart';
import '../../shared/models/user_model.dart';

@singleton
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw AppException('Failed to get user data: $e');
    }
  }

  // Username helpers
  Future<bool> isUsernameTaken(String username) async {
    try {
      final doc = await _firestore.collection('usernames').doc(username.toLowerCase()).get();
      return doc.exists;
    } catch (e) {
      throw AppException('Failed to check username: $e');
    }
  }

  Future<void> setMyUsername(String username) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AppException('No authenticated user');
      final uname = username.toLowerCase();
      // Use a transaction to avoid race conditions
      await _firestore.runTransaction((tx) async {
        final unameRef = _firestore.collection('usernames').doc(uname);
        final unameSnap = await tx.get(unameRef);
        if (unameSnap.exists) {
          throw const AppException('Username already taken');
        }
        // set reservation
        tx.set(unameRef, {
          'uid': user.uid,
          'createdAt': Timestamp.now(),
        });
        // update user doc
        final userRef = _firestore.collection(AppConstants.firestoreUsersCollection).doc(user.uid);
        tx.set(userRef, {
          'username': uname,
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to set username: $e');
    }
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final uname = username.toLowerCase();
      final map = await _firestore.collection('usernames').doc(uname).get();
      if (!map.exists) return null;
      final uid = (map.data() ?? const {})['uid'] as String?;
      if (uid == null) return null;
      return getUserById(uid);
    } catch (e) {
      throw AppException('Failed to get user by username: $e');
    }
  }

  // Resolve a username to UID without reading the user document
  Future<String?> resolveUsernameToUid(String username) async {
    try {
      final uname = username.toLowerCase();
      final snap = await _firestore.collection('usernames').doc(uname).get();
      if (!snap.exists) return null;
      return (snap.data() ?? const {})['uid'] as String?;
    } catch (e) {
      throw AppException('Failed to resolve username: $e');
    }
  }

  // Stream of current user data
  Stream<UserModel?> getCurrentUserStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(AppConstants.firestoreUsersCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Create new user profile
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(user.id)
          .set(user.copyWith(isDiscoverable: true).toFirestore());
    } catch (e) {
      throw AppException('Failed to create user: $e');
    }
  }

  // Update user profile
  Future<void> updateUser(UserModel user) async {
    try {
      // Use merge to create the document if it doesn't exist and to avoid update() not-found errors
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(user.id)
          .set(
        user
            .copyWith(
              updatedAt: DateTime.now(),
              isDiscoverable: true,
            )
            .toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw AppException('Failed to update user: $e');
    }
  }

  // Update user location
  Future<void> updateUserLocation(String userId, Location location) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .update({
        'location': location.toJson(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw AppException('Failed to update location: $e');
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .update({
        'isOnline': isOnline,
        'lastSeen': isOnline ? null : Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw AppException('Failed to update online status: $e');
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw AppException('Failed to get user: $e');
    }
  }

  // Get multiple users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final docs = await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return docs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw AppException('Failed to get users: $e');
    }
  }

  // Search users for discovery
  Future<List<UserModel>> getDiscoverableUsers({
    required String currentUserId,
    int? ageMin,
    int? ageMax,
    double? maxDistance,
    List<String>? interests,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(AppConstants.firestoreUsersCollection);

      // Exclude current user
      query = query.where(FieldPath.documentId, isNotEqualTo: currentUserId);

      // TODO: Add more sophisticated filtering based on preferences
      // For now, just get some random users
      final docs = await query.limit(limit).get();

      return docs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw AppException('Failed to get discoverable users: $e');
    }
  }

  // Update interests
  Future<void> updateInterests(String userId, List<String> interests) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .update({
        'interests': interests,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw AppException('Failed to update interests: $e');
    }
  }

  // Update personality type
  Future<void> updatePersonalityType(String userId, MBTIType personalityType) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .update({
        'personalityType': personalityType.name, // Store as string
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw AppException('Failed to update personality type: $e');
    }
  }

  // Alias method for personality test page
  Future<void> updateUserPersonality(MBTIType personalityType) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw const AppException('No authenticated user');
    }
    await updatePersonalityType(currentUser.uid, personalityType);
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw AppException('Failed to delete user: $e');
    }
  }

  // Block user
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .set({
        'userId': targetUserId,
        'blockedAt': Timestamp.now(),
      });
    } catch (e) {
      throw AppException('Failed to block user: $e');
    }
  }

  // Unblock user
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .delete();
    } catch (e) {
      throw AppException('Failed to unblock user: $e');
    }
  }

  // Get blocked users
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final docs = await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .collection('blocked_users')
          .get();

      return docs.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw AppException('Failed to get blocked users: $e');
    }
  }

  // Report user
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });
    } catch (e) {
      throw AppException('Failed to report user: $e');
    }
  }

  // Toggle discoverability
  Future<void> setDiscoverable(String userId, bool value) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(userId)
          .update({'isDiscoverable': value, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw AppException('Failed to update discoverability: $e');
    }
  }
}

// Provider for UserService
final userServiceProvider = Provider<UserService>((ref) => UserService());

// Provider for current user
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userService = ref.read(userServiceProvider);
  return userService.getCurrentUserStream();
});
