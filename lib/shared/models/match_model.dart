import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'match_model.g.dart';

@JsonSerializable()
class MatchModel {
  final String id;
  final String userId1;
  final String userId2;
  final MatchStatus status;
  final double compatibilityScore;
  final List<String> commonInterests;
  final CompatibilityBreakdown compatibilityBreakdown;
  final DateTime createdAt;
  final DateTime? matchedAt;
  final DateTime? expiresAt;
  final MatchInitiator initiator;
  final String? rejectionReason;

  MatchModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.compatibilityScore,
    required this.commonInterests,
    required this.compatibilityBreakdown,
    required this.createdAt,
    this.matchedAt,
    this.expiresAt,
    required this.initiator,
    this.rejectionReason,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) => _$MatchModelFromJson(json);
  Map<String, dynamic> toJson() => _$MatchModelToJson(this);

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'matchedAt': data['matchedAt'] != null
          ? (data['matchedAt'] as Timestamp).toDate().toIso8601String()
          : null,
      'expiresAt': data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return {
      ...json,
      'createdAt': Timestamp.fromDate(createdAt),
      'matchedAt': matchedAt != null ? Timestamp.fromDate(matchedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    }..remove('id');
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == userId1 ? userId2 : userId1;
  }

  bool isExpired() {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  MatchModel copyWith({
    String? id,
    String? userId1,
    String? userId2,
    MatchStatus? status,
    double? compatibilityScore,
    List<String>? commonInterests,
    CompatibilityBreakdown? compatibilityBreakdown,
    DateTime? createdAt,
    DateTime? matchedAt,
    DateTime? expiresAt,
    MatchInitiator? initiator,
    String? rejectionReason,
  }) {
    return MatchModel(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      status: status ?? this.status,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      commonInterests: commonInterests ?? this.commonInterests,
      compatibilityBreakdown: compatibilityBreakdown ?? this.compatibilityBreakdown,
      createdAt: createdAt ?? this.createdAt,
      matchedAt: matchedAt ?? this.matchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      initiator: initiator ?? this.initiator,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

@JsonSerializable()
class CompatibilityBreakdown {
  final double personalityScore;
  final double interestsScore;
  final double locationScore;
  final double ageCompatibilityScore;
  final double overallScore;
  final List<CompatibilityFactor> topFactors;

  CompatibilityBreakdown({
    required this.personalityScore,
    required this.interestsScore,
    required this.locationScore,
    required this.ageCompatibilityScore,
    required this.overallScore,
    required this.topFactors,
  });

  factory CompatibilityBreakdown.fromJson(Map<String, dynamic> json) => 
      _$CompatibilityBreakdownFromJson(json);
  Map<String, dynamic> toJson() => _$CompatibilityBreakdownToJson(this);
}

@JsonSerializable()
class CompatibilityFactor {
  final String name;
  final double score;
  final String description;
  final FactorType type;

  CompatibilityFactor({
    required this.name,
    required this.score,
    required this.description,
    required this.type,
  });

  factory CompatibilityFactor.fromJson(Map<String, dynamic> json) => 
      _$CompatibilityFactorFromJson(json);
  Map<String, dynamic> toJson() => _$CompatibilityFactorToJson(this);
}

enum MatchStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('potential')
  potential,
  @JsonValue('active')
  active,
  @JsonValue('liked')
  liked,
  @JsonValue('matched')
  matched,
  @JsonValue('rejected')
  rejected,
  @JsonValue('expired')
  expired,
  @JsonValue('blocked')
  blocked,
}

enum MatchInitiator {
  @JsonValue('user1')
  user1,
  @JsonValue('user2')
  user2,
  @JsonValue('mutual')
  mutual,
  @JsonValue('system')
  system,
}

enum FactorType {
  @JsonValue('personality')
  personality,
  @JsonValue('interests')
  interests,
  @JsonValue('location')
  location,
  @JsonValue('lifestyle')
  lifestyle,
  @JsonValue('personal_values')
  personalValues,
}
