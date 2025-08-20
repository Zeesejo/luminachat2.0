import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

enum MBTIType {
  intj, intp, entj, entp,
  infj, infp, enfj, enfp,
  istj, isfj, estj, esfj,
  istp, isfp, estp, esfp
}

enum Gender {
  male,
  female,
  nonBinary,
  preferNotToSay,
}

extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male: return 'Male';
      case Gender.female: return 'Female';
      case Gender.nonBinary: return 'Non-binary';
      case Gender.preferNotToSay: return 'Prefer not to say';
    }
  }
}

extension MBTITypeExtension on MBTIType {
  String get type => name.toUpperCase();
  
  String get title {
    switch (this) {
      case MBTIType.intj: return 'The Architect';
      case MBTIType.intp: return 'The Thinker';
      case MBTIType.entj: return 'The Commander';
      case MBTIType.entp: return 'The Debater';
      case MBTIType.infj: return 'The Advocate';
      case MBTIType.infp: return 'The Mediator';
      case MBTIType.enfj: return 'The Protagonist';
      case MBTIType.enfp: return 'The Campaigner';
      case MBTIType.istj: return 'The Logistician';
      case MBTIType.isfj: return 'The Protector';
      case MBTIType.estj: return 'The Executive';
      case MBTIType.esfj: return 'The Consul';
      case MBTIType.istp: return 'The Virtuoso';
      case MBTIType.isfp: return 'The Adventurer';
      case MBTIType.estp: return 'The Entrepreneur';
      case MBTIType.esfp: return 'The Entertainer';
    }
  }
  
  String get description {
    switch (this) {
      case MBTIType.intj: return 'Imaginative and strategic thinkers, with a plan for everything.';
      case MBTIType.intp: return 'Innovative inventors with an unquenchable thirst for knowledge.';
      case MBTIType.entj: return 'Bold, imaginative and strong-willed leaders.';
      case MBTIType.entp: return 'Smart and curious thinkers who cannot resist an intellectual challenge.';
      case MBTIType.infj: return 'Quiet and mystical, yet very inspiring and tireless idealists.';
      case MBTIType.infp: return 'Poetic, kind and altruistic people, always eager to help.';
      case MBTIType.enfj: return 'Charismatic and inspiring leaders, able to mesmerize their listeners.';
      case MBTIType.enfp: return 'Enthusiastic, creative and sociable free spirits.';
      case MBTIType.istj: return 'Practical and fact-minded, reliable and responsible.';
      case MBTIType.isfj: return 'Very dedicated and warm protectors, always ready to defend their loved ones.';
      case MBTIType.estj: return 'Excellent administrators, unsurpassed at managing things or people.';
      case MBTIType.esfj: return 'Extraordinarily caring, social and popular people, always eager to help.';
      case MBTIType.istp: return 'Bold and practical experimenters, masters of all kinds of tools.';
      case MBTIType.isfp: return 'Flexible and charming artists, always ready to explore new possibilities.';
      case MBTIType.estp: return 'Smart, energetic and very perceptive people, truly enjoy living on the edge.';
      case MBTIType.esfp: return 'Spontaneous, energetic and enthusiastic people - life is never boring.';
    }
  }
}

@JsonSerializable()
class AgeRange {
  final int start;
  final int end;

  AgeRange({required this.start, required this.end});

  factory AgeRange.fromJson(Map<String, dynamic> json) => _$AgeRangeFromJson(json);
  Map<String, dynamic> toJson() => _$AgeRangeToJson(this);
}

@JsonSerializable()
class UserPreferences {
  final AgeRange? ageRange;
  final double maxDistance;
  final List<String>? preferredInterests;
  final bool showOnlyVerified;

  UserPreferences({
    this.ageRange,
    this.maxDistance = 50.0,
    this.preferredInterests,
    this.showOnlyVerified = false,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);
}

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? bio;
  final DateTime birthDate;
  final Gender? gender;
  final String? profileImageUrl;
  final List<String> interests;
  final MBTIType? personalityType;
  final Location? location;
  final List<String> photos;
  final PrivacySettings privacySettings;
  final ProfileCompletion profileCompletion;
  final UserPreferences? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isVerified;
  @JsonKey(defaultValue: true)
  final bool isDiscoverable;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    required this.birthDate,
    this.gender,
    this.profileImageUrl,
    this.interests = const [],
    this.personalityType,
    this.location,
    this.photos = const [],
    required this.privacySettings,
    required this.profileCompletion,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline = false,
    this.lastSeen,
    this.isVerified = false,
    this.isDiscoverable = true,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  double get profileCompletionPercentage {
    int completed = 0;
    int total = 8;

    if (name.isNotEmpty) completed++;
    if (bio != null && bio!.isNotEmpty) completed++;
    if (profileImageUrl != null) completed++;
    if (interests.isNotEmpty) completed++;
    if (personalityType != null) completed++;
    if (location != null) completed++;
    if (photos.length >= 2) completed++;
    if (isVerified) completed++;

    return (completed / total) * 100;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({
      'id': doc.id,
      ...data,
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'updatedAt': (data['updatedAt'] as Timestamp).toDate().toIso8601String(),
      'birthDate': (data['birthDate'] as Timestamp).toDate().toIso8601String(),
      'lastSeen': data['lastSeen'] != null 
          ? (data['lastSeen'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    return {
      ...json,
  // Ensure nested objects are properly serialized to Maps for Firestore
  'location': location?.toJson(),
  'privacySettings': privacySettings.toJson(),
  'profileCompletion': profileCompletion.toJson(),
  'preferences': preferences?.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'birthDate': Timestamp.fromDate(birthDate),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    }..remove('id');
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? bio,
    DateTime? birthDate,
    Gender? gender,
    String? profileImageUrl,
    List<String>? interests,
    MBTIType? personalityType,
    Location? location,
    List<String>? photos,
    PrivacySettings? privacySettings,
    ProfileCompletion? profileCompletion,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isVerified,
    bool? isDiscoverable,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      interests: interests ?? this.interests,
      personalityType: personalityType ?? this.personalityType,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      privacySettings: privacySettings ?? this.privacySettings,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
    );
  }
}

@JsonSerializable()
class PersonalityProfile {
  final MBTIType type;
  final String title;
  final String description;
  final List<String> strengths;
  final List<String> weaknesses;
  final double? compatibilityScore;

  PersonalityProfile({
    required this.type,
    required this.title,
    required this.description,
    required this.strengths,
    required this.weaknesses,
    this.compatibilityScore,
  });

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) => 
      _$PersonalityProfileFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalityProfileToJson(this);
}

@JsonSerializable()
class Location {
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final String country;
  final String formattedAddress;

  Location({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.country,
    required this.formattedAddress,
  });

  factory Location.fromJson(Map<String, dynamic> json) => 
      _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

@JsonSerializable()
class PrivacySettings {
  final bool showAge;
  final bool showLocation;
  final bool showOnlineStatus;
  final bool allowMessagesFromMatches;
  final bool allowLocationSharing;
  final double maxDistance; // in kilometers

  PrivacySettings({
    this.showAge = true,
    this.showLocation = true,
    this.showOnlineStatus = true,
    this.allowMessagesFromMatches = true,
    this.allowLocationSharing = false,
    this.maxDistance = 50.0,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => 
      _$PrivacySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);
}

@JsonSerializable()
class ProfileCompletion {
  final bool hasProfilePhoto;
  final bool hasBio;
  final bool hasInterests;
  final bool hasPersonalityTest;
  final bool hasLocation;
  final bool hasMultiplePhotos;
  final bool isEmailVerified;
  final bool hasPhoneNumber;

  ProfileCompletion({
    this.hasProfilePhoto = false,
    this.hasBio = false,
    this.hasInterests = false,
    this.hasPersonalityTest = false,
    this.hasLocation = false,
    this.hasMultiplePhotos = false,
    this.isEmailVerified = false,
    this.hasPhoneNumber = false,
  });

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) => 
      _$ProfileCompletionFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileCompletionToJson(this);

  ProfileCompletion copyWith({
    bool? hasProfilePhoto,
    bool? hasBio,
    bool? hasInterests,
    bool? hasPersonalityTest,
    bool? hasLocation,
    bool? hasMultiplePhotos,
    bool? isEmailVerified,
    bool? hasPhoneNumber,
  }) {
    return ProfileCompletion(
      hasProfilePhoto: hasProfilePhoto ?? this.hasProfilePhoto,
      hasBio: hasBio ?? this.hasBio,
      hasInterests: hasInterests ?? this.hasInterests,
      hasPersonalityTest: hasPersonalityTest ?? this.hasPersonalityTest,
      hasLocation: hasLocation ?? this.hasLocation,
      hasMultiplePhotos: hasMultiplePhotos ?? this.hasMultiplePhotos,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      hasPhoneNumber: hasPhoneNumber ?? this.hasPhoneNumber,
    );
  }
}
