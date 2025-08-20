// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgeRange _$AgeRangeFromJson(Map<String, dynamic> json) => AgeRange(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
    );

Map<String, dynamic> _$AgeRangeToJson(AgeRange instance) => <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
    };

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      ageRange: json['ageRange'] == null
          ? null
          : AgeRange.fromJson(json['ageRange'] as Map<String, dynamic>),
      maxDistance: (json['maxDistance'] as num?)?.toDouble() ?? 50.0,
      preferredInterests: (json['preferredInterests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      showOnlyVerified: json['showOnlyVerified'] as bool? ?? false,
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'ageRange': instance.ageRange,
      'maxDistance': instance.maxDistance,
      'preferredInterests': instance.preferredInterests,
      'showOnlyVerified': instance.showOnlyVerified,
    };

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      birthDate: DateTime.parse(json['birthDate'] as String),
      gender: $enumDecodeNullable(_$GenderEnumMap, json['gender']),
      profileImageUrl: json['profileImageUrl'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      personalityType:
          $enumDecodeNullable(_$MBTITypeEnumMap, json['personalityType']),
      location: json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      privacySettings: PrivacySettings.fromJson(
          json['privacySettings'] as Map<String, dynamic>),
      profileCompletion: ProfileCompletion.fromJson(
          json['profileCompletion'] as Map<String, dynamic>),
      preferences: json['preferences'] == null
          ? null
          : UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      isDiscoverable: json['isDiscoverable'] as bool? ?? true,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'bio': instance.bio,
      'birthDate': instance.birthDate.toIso8601String(),
      'gender': _$GenderEnumMap[instance.gender],
      'profileImageUrl': instance.profileImageUrl,
      'interests': instance.interests,
      'personalityType': _$MBTITypeEnumMap[instance.personalityType],
      'location': instance.location,
      'photos': instance.photos,
      'privacySettings': instance.privacySettings,
      'profileCompletion': instance.profileCompletion,
      'preferences': instance.preferences,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isOnline': instance.isOnline,
      'lastSeen': instance.lastSeen?.toIso8601String(),
      'isVerified': instance.isVerified,
      'isDiscoverable': instance.isDiscoverable,
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
  Gender.nonBinary: 'nonBinary',
  Gender.preferNotToSay: 'preferNotToSay',
};

const _$MBTITypeEnumMap = {
  MBTIType.intj: 'intj',
  MBTIType.intp: 'intp',
  MBTIType.entj: 'entj',
  MBTIType.entp: 'entp',
  MBTIType.infj: 'infj',
  MBTIType.infp: 'infp',
  MBTIType.enfj: 'enfj',
  MBTIType.enfp: 'enfp',
  MBTIType.istj: 'istj',
  MBTIType.isfj: 'isfj',
  MBTIType.estj: 'estj',
  MBTIType.esfj: 'esfj',
  MBTIType.istp: 'istp',
  MBTIType.isfp: 'isfp',
  MBTIType.estp: 'estp',
  MBTIType.esfp: 'esfp',
};

PersonalityProfile _$PersonalityProfileFromJson(Map<String, dynamic> json) =>
    PersonalityProfile(
      type: $enumDecode(_$MBTITypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      strengths:
          (json['strengths'] as List<dynamic>).map((e) => e as String).toList(),
      weaknesses: (json['weaknesses'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      compatibilityScore: (json['compatibilityScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PersonalityProfileToJson(PersonalityProfile instance) =>
    <String, dynamic>{
      'type': _$MBTITypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'strengths': instance.strengths,
      'weaknesses': instance.weaknesses,
      'compatibilityScore': instance.compatibilityScore,
    };

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String,
      state: json['state'] as String,
      country: json['country'] as String,
      formattedAddress: json['formattedAddress'] as String,
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'formattedAddress': instance.formattedAddress,
    };

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) =>
    PrivacySettings(
      showAge: json['showAge'] as bool? ?? true,
      showLocation: json['showLocation'] as bool? ?? true,
      showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
      allowMessagesFromMatches:
          json['allowMessagesFromMatches'] as bool? ?? true,
      allowLocationSharing: json['allowLocationSharing'] as bool? ?? false,
      maxDistance: (json['maxDistance'] as num?)?.toDouble() ?? 50.0,
    );

Map<String, dynamic> _$PrivacySettingsToJson(PrivacySettings instance) =>
    <String, dynamic>{
      'showAge': instance.showAge,
      'showLocation': instance.showLocation,
      'showOnlineStatus': instance.showOnlineStatus,
      'allowMessagesFromMatches': instance.allowMessagesFromMatches,
      'allowLocationSharing': instance.allowLocationSharing,
      'maxDistance': instance.maxDistance,
    };

ProfileCompletion _$ProfileCompletionFromJson(Map<String, dynamic> json) =>
    ProfileCompletion(
      hasProfilePhoto: json['hasProfilePhoto'] as bool? ?? false,
      hasBio: json['hasBio'] as bool? ?? false,
      hasInterests: json['hasInterests'] as bool? ?? false,
      hasPersonalityTest: json['hasPersonalityTest'] as bool? ?? false,
      hasLocation: json['hasLocation'] as bool? ?? false,
      hasMultiplePhotos: json['hasMultiplePhotos'] as bool? ?? false,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      hasPhoneNumber: json['hasPhoneNumber'] as bool? ?? false,
    );

Map<String, dynamic> _$ProfileCompletionToJson(ProfileCompletion instance) =>
    <String, dynamic>{
      'hasProfilePhoto': instance.hasProfilePhoto,
      'hasBio': instance.hasBio,
      'hasInterests': instance.hasInterests,
      'hasPersonalityTest': instance.hasPersonalityTest,
      'hasLocation': instance.hasLocation,
      'hasMultiplePhotos': instance.hasMultiplePhotos,
      'isEmailVerified': instance.isEmailVerified,
      'hasPhoneNumber': instance.hasPhoneNumber,
    };
