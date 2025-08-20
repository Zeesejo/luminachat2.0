// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchModel _$MatchModelFromJson(Map<String, dynamic> json) => MatchModel(
      id: json['id'] as String,
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      status: $enumDecode(_$MatchStatusEnumMap, json['status']),
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      commonInterests: (json['commonInterests'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      compatibilityBreakdown: CompatibilityBreakdown.fromJson(
          json['compatibilityBreakdown'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      matchedAt: json['matchedAt'] == null
          ? null
          : DateTime.parse(json['matchedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      initiator: $enumDecode(_$MatchInitiatorEnumMap, json['initiator']),
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$MatchModelToJson(MatchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId1': instance.userId1,
      'userId2': instance.userId2,
      'status': _$MatchStatusEnumMap[instance.status]!,
      'compatibilityScore': instance.compatibilityScore,
      'commonInterests': instance.commonInterests,
      'compatibilityBreakdown': instance.compatibilityBreakdown,
      'createdAt': instance.createdAt.toIso8601String(),
      'matchedAt': instance.matchedAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'initiator': _$MatchInitiatorEnumMap[instance.initiator]!,
      'rejectionReason': instance.rejectionReason,
    };

const _$MatchStatusEnumMap = {
  MatchStatus.pending: 'pending',
  MatchStatus.potential: 'potential',
  MatchStatus.active: 'active',
  MatchStatus.liked: 'liked',
  MatchStatus.matched: 'matched',
  MatchStatus.rejected: 'rejected',
  MatchStatus.expired: 'expired',
  MatchStatus.blocked: 'blocked',
};

const _$MatchInitiatorEnumMap = {
  MatchInitiator.user1: 'user1',
  MatchInitiator.user2: 'user2',
  MatchInitiator.mutual: 'mutual',
  MatchInitiator.system: 'system',
};

CompatibilityBreakdown _$CompatibilityBreakdownFromJson(
        Map<String, dynamic> json) =>
    CompatibilityBreakdown(
      personalityScore: (json['personalityScore'] as num).toDouble(),
      interestsScore: (json['interestsScore'] as num).toDouble(),
      locationScore: (json['locationScore'] as num).toDouble(),
      ageCompatibilityScore: (json['ageCompatibilityScore'] as num).toDouble(),
      overallScore: (json['overallScore'] as num).toDouble(),
      topFactors: (json['topFactors'] as List<dynamic>)
          .map((e) => CompatibilityFactor.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CompatibilityBreakdownToJson(
        CompatibilityBreakdown instance) =>
    <String, dynamic>{
      'personalityScore': instance.personalityScore,
      'interestsScore': instance.interestsScore,
      'locationScore': instance.locationScore,
      'ageCompatibilityScore': instance.ageCompatibilityScore,
      'overallScore': instance.overallScore,
      'topFactors': instance.topFactors,
    };

CompatibilityFactor _$CompatibilityFactorFromJson(Map<String, dynamic> json) =>
    CompatibilityFactor(
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      description: json['description'] as String,
      type: $enumDecode(_$FactorTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$CompatibilityFactorToJson(
        CompatibilityFactor instance) =>
    <String, dynamic>{
      'name': instance.name,
      'score': instance.score,
      'description': instance.description,
      'type': _$FactorTypeEnumMap[instance.type]!,
    };

const _$FactorTypeEnumMap = {
  FactorType.personality: 'personality',
  FactorType.interests: 'interests',
  FactorType.location: 'location',
  FactorType.lifestyle: 'lifestyle',
  FactorType.personalValues: 'personal_values',
};
