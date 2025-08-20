import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart' hide Environment;
// FirebaseException is re-exported by cloud_firestore
import 'package:firebase_auth/firebase_auth.dart';

import '../config/environment.dart';
import '../utils/exceptions.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/match_model.dart';

@singleton
class MatchingService {
  // Avoid initializing Firestore when Firebase is disabled
  FirebaseFirestore get _firestore {
    if (!Environment.useFirebase) {
      throw const AppException('Firestore is disabled in mock mode');
    }
    return FirebaseFirestore.instance;
  }

  // Get potential matches for a user
  Future<List<MatchModel>> findPotentialMatches({
    required String userId,
    int limit = 20,
  }) async {
    // In mock mode, generate placeholder matches without Firestore
    if (!Environment.useFirebase) {
      return _generateMockMatches(userId, limit);
    }

    try {
      var user = await _firestore.collection('users').doc(userId).get();
      if (!user.exists) {
        // Try to bootstrap a minimal user profile if authenticated
        await _bootstrapUserDoc(userId);
        user = await _firestore.collection('users').doc(userId).get();
      }
      if (!user.exists) {
  throw const AppException('User not found');
      }

      final currentUser = UserModel.fromFirestore(user);
      
      // Get users who haven't been matched with this user yet
      final excludedUserIds = await _getExcludedUserIds(userId);
      
      // Query potential matches based on preferences
      final query = _buildMatchQuery(currentUser, excludedUserIds);
      final snapshot = await query.get();
      
      List<MatchModel> matches = [];
      
      for (var doc in snapshot.docs) {
        final potentialMatch = UserModel.fromFirestore(doc);
        
        // Skip if this user doesn't meet the current user's preferences
        if (!_meetsPreferences(currentUser, potentialMatch)) continue;
        
        // Skip if current user doesn't meet the potential match's preferences
        if (!_meetsPreferences(potentialMatch, currentUser)) continue;
        
        // Calculate compatibility
        final compatibility = _calculateCompatibility(currentUser, potentialMatch);
        
        if (compatibility.overallScore >= 50) { // Minimum compatibility threshold
          final match = MatchModel(
            id: _generateMatchId(userId, potentialMatch.id),
            userId1: userId,
            userId2: potentialMatch.id,
            status: MatchStatus.potential,
            compatibilityScore: compatibility.overallScore,
            commonInterests: _getCommonInterests(currentUser, potentialMatch),
            compatibilityBreakdown: compatibility,
            createdAt: DateTime.now(),
            initiator: MatchInitiator.system,
          );
          
          matches.add(match);
        }
      }
      
      // Sort by compatibility score
      matches.sort((a, b) => b.compatibilityBreakdown.overallScore.compareTo(a.compatibilityBreakdown.overallScore));
      
      return matches.take(limit).toList();
    } on FirebaseException catch (e) {
      // If rules are strict and deny reading other users, fall back to mock matches
      if (e.code == 'permission-denied') {
        return _generateMockMatches(userId, limit);
      }
      throw AppException('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to find potential matches: $e');
    }
  }

  Future<void> _bootstrapUserDoc(String userId) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null || user.uid != userId) return;
      final now = Timestamp.now();
      final docRef = _firestore.collection('users').doc(userId);
      await docRef.set({
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
      }, SetOptions(merge: true));
    } catch (_) {
      // ignore; rules might block
    }
  }

  // Create a match between two users
  Future<MatchModel> createMatch({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final user1Doc = await _firestore.collection('users').doc(userId1).get();
      final user2Doc = await _firestore.collection('users').doc(userId2).get();
      
      if (!user1Doc.exists || !user2Doc.exists) {
        throw const AppException('One or both users not found');
      }
      
      final user1 = UserModel.fromFirestore(user1Doc);
      final user2 = UserModel.fromFirestore(user2Doc);
      
      final compatibility = _calculateCompatibility(user1, user2);
      
      final match = MatchModel(
        id: _generateMatchId(userId1, userId2),
        userId1: userId1,
        userId2: userId2,
        status: MatchStatus.matched,
        compatibilityScore: compatibility.overallScore,
        commonInterests: _getCommonInterests(user1, user2),
        compatibilityBreakdown: compatibility,
        createdAt: DateTime.now(),
        matchedAt: DateTime.now(),
        initiator: MatchInitiator.mutual,
      );
      
      // Store match with participants array used by queries and rules
      await _firestore.collection('matches').doc(match.id).set({
        ...match.toFirestore(),
        'participants': [userId1, userId2],
      });
      
      // Update both users' match lists (best-effort; ignore if rules deny)
      try {
        await _firestore.collection('users').doc(userId1).update({
          'matches': FieldValue.arrayUnion([userId2]),
        });
      } catch (_) {}
      
      try {
        await _firestore.collection('users').doc(userId2).update({
          'matches': FieldValue.arrayUnion([userId1]),
        });
      } catch (_) {}
      
      return match;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AppException('You do not have permission to perform this action.');
      }
      throw AppException('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to create match: $e');
    }
  }

  // Get user's matches
  Stream<List<MatchModel>> getUserMatches(String userId) {
    if (!Environment.useFirebase) {
      // In mock mode, emit an empty list
      return Stream.value(<MatchModel>[]);
    }
    return _firestore
        .collection('matches')
        .where('participants', arrayContains: userId)
        .where('status', whereIn: [MatchStatus.matched.name, MatchStatus.potential.name])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            throw const AppException('You do not have permission to view matches.');
          }
        })
        .map((snapshot) {
      return snapshot.docs.map((doc) => MatchModel.fromFirestore(doc)).toList();
    });
  }

  // Like a user (swipe right)
  Future<bool> likeUser({
    required String currentUserId,
    required String likedUserId,
  }) async {
    try {
      // Best-effort check for a reciprocal like. If rules deny reads, we still proceed to write our like.
      bool reciprocalLikeDetected = false;
      try {
        final existingLike = await _firestore
            .collection('likes')
            .where('fromUserId', isEqualTo: likedUserId)
            .where('toUserId', isEqualTo: currentUserId)
            .limit(1)
            .get();
        reciprocalLikeDetected = existingLike.docs.isNotEmpty;
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        // Ignore permission-denied on read to avoid surfacing errors under strict rules
        reciprocalLikeDetected = false;
      }
      
      await _firestore.collection('likes').add({
        'fromUserId': currentUserId,
        'toUserId': likedUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (reciprocalLikeDetected) {
        await createMatch(userId1: currentUserId, userId2: likedUserId);
        return true;
      }
      
      return false;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AppException('You do not have permission to like this user.');
      }
      throw AppException('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      throw AppException('Failed to like user: $e');
    }
  }

  // Pass on a user (swipe left)
  Future<void> passUser({
    required String currentUserId,
    required String passedUserId,
  }) async {
    try {
      // Record a pass action. Rules typically allow create-only for this collection.
      await _firestore.collection('passes').add({
        'fromUserId': currentUserId,
        'toUserId': passedUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AppException('You do not have permission to pass on this user.');
      }
      throw AppException('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      throw AppException('Failed to pass user: $e');
    }
  }

  // Update match status
  Future<void> updateMatchStatus({
    required String matchId,
    required MatchStatus status,
  }) async {
    try {
      await _firestore.collection('matches').doc(matchId).update({
        'status': status.name,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const AppException('You do not have permission to update this match.');
      }
      throw AppException('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      throw AppException('Failed to update match status: $e');
    }
  }

  // Calculate compatibility between two users
  CompatibilityBreakdown _calculateCompatibility(UserModel user1, UserModel user2) {
    List<CompatibilityFactor> factors = [];
    double totalScore = 0;
    int factorCount = 0;

    // Personality compatibility (40% weight)
    if (user1.personalityType != null && user2.personalityType != null) {
      final personalityScore = _calculatePersonalityCompatibility(
        user1.personalityType!,
        user2.personalityType!,
      );
      factors.add(CompatibilityFactor(
        name: 'Personality Match',
        score: personalityScore,
        type: FactorType.personality,
        description: _getPersonalityDescription(user1.personalityType!, user2.personalityType!),
      ));
      totalScore += personalityScore * 0.4;
      factorCount++;
    }

    // Interests compatibility (30% weight)
    if (user1.interests.isNotEmpty && user2.interests.isNotEmpty) {
      final interestsScore = _calculateInterestsCompatibility(user1.interests, user2.interests);
      factors.add(CompatibilityFactor(
        name: 'Shared Interests',
        score: interestsScore,
        type: FactorType.interests,
        description: _getInterestsDescription(user1.interests, user2.interests),
      ));
      totalScore += interestsScore * 0.3;
      factorCount++;
    }

    // Age compatibility (15% weight)
    final u1Age = user1.age;
    final u2Age = user2.age;
    final ageScore = _calculateAgeCompatibility(u1Age, u2Age);
    factors.add(CompatibilityFactor(
      name: 'Age Compatibility',
      score: ageScore,
      type: FactorType.lifestyle,
      description: _getAgeDescription(u1Age, u2Age),
    ));
    totalScore += ageScore * 0.15;
    factorCount++;

    // Location proximity (15% weight)
    final loc1 = user1.location;
    final loc2 = user2.location;
    if (loc1 != null && loc2 != null) {
      final locationScore = _calculateLocationCompatibility(loc1, loc2);
      factors.add(CompatibilityFactor(
        name: 'Location Proximity',
        score: locationScore,
        type: FactorType.location,
        description: _getLocationDescription(loc1, loc2),
      ));
      totalScore += locationScore * 0.15;
      factorCount++;
    }

    final overallScore = factorCount > 0 ? (totalScore / factorCount * 100).round() : 0;

    return CompatibilityBreakdown(
      personalityScore: 0,
      interestsScore: 0,
      locationScore: 0,
      ageCompatibilityScore: 0,
      overallScore: overallScore.toDouble(),
      topFactors: factors,
    );
  }

  // Calculate personality type compatibility
  double _calculatePersonalityCompatibility(MBTIType? type1, MBTIType? type2) {
    if (type1 == null || type2 == null) return 0.5;
    
    // Compatibility matrix for MBTI personality types
    const compatibilityMatrix = {
      MBTIType.intj: {
        MBTIType.enfp: 0.95,
        MBTIType.entp: 0.90,
        MBTIType.infj: 0.85,
        MBTIType.intj: 0.80,
        MBTIType.enfj: 0.75,
        MBTIType.infp: 0.70,
        MBTIType.intp: 0.65,
        MBTIType.entj: 0.60,
      },
      MBTIType.infp: {
        MBTIType.enfj: 0.95,
        MBTIType.entj: 0.90,
        MBTIType.infj: 0.85,
        MBTIType.enfp: 0.80,
        MBTIType.intj: 0.75,
        MBTIType.infp: 0.70,
        MBTIType.entp: 0.65,
        MBTIType.intp: 0.60,
      },
      MBTIType.enfp: {
        MBTIType.intj: 0.95,
        MBTIType.infj: 0.90,
        MBTIType.enfj: 0.85,
        MBTIType.entj: 0.80,
        MBTIType.enfp: 0.75,
        MBTIType.infp: 0.70,
        MBTIType.entp: 0.65,
        MBTIType.intp: 0.60,
      },
      MBTIType.infj: {
        MBTIType.enfp: 0.95,
        MBTIType.entp: 0.90,
        MBTIType.intj: 0.85,
        MBTIType.enfj: 0.80,
        MBTIType.infj: 0.75,
        MBTIType.infp: 0.70,
        MBTIType.entj: 0.65,
        MBTIType.intp: 0.60,
      },
      MBTIType.enfj: {
        MBTIType.infp: 0.95,
        MBTIType.isfp: 0.90,
        MBTIType.enfp: 0.85,
        MBTIType.infj: 0.80,
        MBTIType.enfj: 0.75,
        MBTIType.entj: 0.70,
        MBTIType.intj: 0.65,
        MBTIType.entp: 0.60,
      },
      MBTIType.entj: {
        MBTIType.infp: 0.95,
        MBTIType.intp: 0.90,
        MBTIType.enfp: 0.85,
        MBTIType.enfj: 0.80,
        MBTIType.entj: 0.75,
        MBTIType.intj: 0.70,
        MBTIType.infj: 0.65,
        MBTIType.entp: 0.60,
      },
      MBTIType.entp: {
        MBTIType.infj: 0.95,
        MBTIType.intj: 0.90,
        MBTIType.enfj: 0.85,
        MBTIType.enfp: 0.80,
        MBTIType.entj: 0.75,
        MBTIType.entp: 0.70,
        MBTIType.infp: 0.65,
        MBTIType.intp: 0.60,
      },
      MBTIType.intp: {
        MBTIType.entj: 0.95,
        MBTIType.enfj: 0.90,
        MBTIType.intj: 0.85,
        MBTIType.infj: 0.80,
        MBTIType.enfp: 0.75,
        MBTIType.entp: 0.70,
        MBTIType.intp: 0.65,
        MBTIType.infp: 0.60,
      },
    };

    return compatibilityMatrix[type1]?[type2] ?? 0.5;
  }

  // Calculate interests compatibility
  double _calculateInterestsCompatibility(List<String> interests1, List<String> interests2) {
    if (interests1.isEmpty || interests2.isEmpty) return 0.0;
    
    final commonInterests = interests1.where((interest) => interests2.contains(interest)).length;
    final totalUniqueInterests = {...interests1, ...interests2}.length;
    
    // Jaccard similarity coefficient
    return commonInterests / totalUniqueInterests;
  }

  // Calculate age compatibility
  double _calculateAgeCompatibility(int age1, int age2) {
    final ageDifference = (age1 - age2).abs();
    
    if (ageDifference <= 2) return 1.0;
    if (ageDifference <= 5) return 0.8;
    if (ageDifference <= 10) return 0.6;
    if (ageDifference <= 15) return 0.4;
    return 0.2;
  }

  // Calculate location compatibility
  double _calculateLocationCompatibility(Location location1, Location location2) {
    final distance = sqrt(
      pow(location1.latitude - location2.latitude, 2) +
      pow(location1.longitude - location2.longitude, 2)
    );
    
    // Convert to approximate distance in km (rough calculation)
    final distanceKm = distance * 111;
    
    if (distanceKm <= 5) return 1.0;
    if (distanceKm <= 25) return 0.8;
    if (distanceKm <= 50) return 0.6;
    if (distanceKm <= 100) return 0.4;
    return 0.2;
  }

  // Get users to exclude from matching
  Future<List<String>> _getExcludedUserIds(String userId) async {
  // Exclude only self to avoid permission-denied logs from reading likes/passes under strict rules
  // If you later relax rules to allow owner reads, you can re-introduce reads here.
  return [userId];
  }

  // Build query for potential matches
  Query<Map<String, dynamic>> _buildMatchQuery(UserModel user, List<String> excludedIds) {
    Query<Map<String, dynamic>> query = _firestore.collection('users');

    // Only consider discoverable profiles (aligns with rules)
    query = query.where('isDiscoverable', isEqualTo: true);
    
    // Exclude already processed users
    if (excludedIds.isNotEmpty) {
      query = query.where(FieldPath.documentId, whereNotIn: excludedIds.take(10).toList());
    }

    return query.limit(100);
  }

  // Check if a user meets another user's preferences
  bool _meetsPreferences(UserModel user, UserModel candidate) {
    final preferences = user.preferences;
    if (preferences == null) return true;
    
    // Age check
    final ageRange = preferences.ageRange;
    if (ageRange != null) {
      final candAge = candidate.age; // non-null getter
      if (candAge < ageRange.start || candAge > ageRange.end) {
        return false;
      }
    }
    
    // Distance check (simplified)
    final maxDist = preferences.maxDistance; // non-nullable
    final uLoc = user.location;
    final cLoc = candidate.location;
    if (uLoc != null && cLoc != null) {
      final distance = sqrt(
        pow(uLoc.latitude - cLoc.latitude, 2) +
        pow(uLoc.longitude - cLoc.longitude, 2)
      ) * 111; // Rough km calculation
      
      if (distance > maxDist) {
        return false;
      }
    }
    
    return true;
  }

  // Generate match ID
  String _generateMatchId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Helper methods for descriptions
  String _getPersonalityDescription(MBTIType type1, MBTIType type2) {
    if (type1 == type2) {
      return 'You share the same personality type!';
    }
    return 'Your personality types complement each other well.';
  }

  String _getInterestsDescription(List<String> interests1, List<String> interests2) {
    final common = interests1.where((i) => interests2.contains(i)).toList();
    if (common.isEmpty) {
      return 'You have different interests that could complement each other.';
    }
    return 'You both enjoy: ${common.take(3).join(', ')}';
  }

  String _getAgeDescription(int age1, int age2) {
    final diff = (age1 - age2).abs();
    if (diff <= 2) return 'You\'re very close in age.';
    if (diff <= 5) return 'You\'re in similar life stages.';
    return 'You bring different life experiences.';
  }

  String _getLocationDescription(Location loc1, Location loc2) {
    // This would use the LocationService in practice
    return 'You\'re in the same area.';
  }
  // Helper method to get common interests
  List<String> _getCommonInterests(UserModel user1, UserModel user2) {
  final user1Interests = Set<String>.from(user1.interests);
  final user2Interests = Set<String>.from(user2.interests);
    return user1Interests.intersection(user2Interests).toList();
  }

  // Generate mock matches for development without Firebase
  List<MatchModel> _generateMockMatches(String userId, int limit) {
    final random = Random(42);
    final interests = [
      'Hiking', 'Music', 'Cooking', 'Movies', 'Reading', 'Travel', 'Fitness', 'Gaming'
    ];

    List<MatchModel> list = [];
    for (int i = 0; i < limit; i++) {
      final score = 50 + random.nextInt(50); // 50-99
      final common = interests..shuffle(random);
      final factors = [
        CompatibilityFactor(
          name: 'Personality Match',
          score: 60 + random.nextInt(40).toDouble(),
          description: 'Great MBTI synergy in primary traits',
          type: FactorType.personality,
        ),
        CompatibilityFactor(
          name: 'Shared Interests',
          score: 50 + random.nextInt(50).toDouble(),
          description: 'You both enjoy ${common.take(2).join(', ')}',
          type: FactorType.interests,
        ),
      ];

      final breakdown = CompatibilityBreakdown(
        personalityScore: factors[0].score,
        interestsScore: factors[1].score,
        locationScore: 70,
        ageCompatibilityScore: 65,
        overallScore: score.toDouble(),
        topFactors: factors,
      );

      list.add(
        MatchModel(
          id: 'mock_match_$i',
          userId1: userId,
          userId2: 'mock_user_${i + 1}',
          status: MatchStatus.potential,
          compatibilityScore: breakdown.overallScore,
          commonInterests: common.take(3).toList(),
          compatibilityBreakdown: breakdown,
          createdAt: DateTime.now().subtract(Duration(minutes: i * 5)),
          initiator: MatchInitiator.system,
        ),
      );
    }
    return list;
  }
}

// Provider for MatchingService
final matchingServiceProvider = Provider<MatchingService>((ref) => MatchingService());

// Provider for potential matches
final potentialMatchesProvider = FutureProvider.family<List<MatchModel>, String>((ref, userId) async {
  final matchingService = ref.read(matchingServiceProvider);
  return await matchingService.findPotentialMatches(userId: userId);
});

// Provider for user matches stream
final userMatchesProvider = StreamProvider.family<List<MatchModel>, String>((ref, userId) {
  final matchingService = ref.read(matchingServiceProvider);
  return matchingService.getUserMatches(userId);
});
