import 'dart:async';
import '../../shared/models/user_model.dart';

class MockUserService {
  final Map<String, UserModel> _mockUsers = {};
  
  Future<UserModel?> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockUsers[userId];
  }
  
  Stream<UserModel?> watchCurrentUser() {
    // Return a mock user for testing
    final mockUser = UserModel(
      id: 'mock_user_123',
      email: 'test@example.com',
      name: 'Test User',
      birthDate: DateTime(2000, 1, 1),
      bio: 'This is a test user for development',
      interests: const ['Music', 'Travel', 'Cooking'],
      personalityType: MBTIType.entj,
      location: Location(
        latitude: 37.7749,
        longitude: -122.4194,
        city: 'San Francisco',
        state: 'CA',
        country: 'USA',
        formattedAddress: 'San Francisco, CA, USA',
      ),
  photos: const [],
      privacySettings: PrivacySettings(
        showAge: true,
        showLocation: true,
        showOnlineStatus: true,
        allowMessagesFromMatches: true,
        allowLocationSharing: false,
        maxDistance: 50.0,
      ),
      profileCompletion: ProfileCompletion(
        hasProfilePhoto: true,
        hasBio: true,
        hasInterests: true,
        hasPersonalityTest: true,
        hasLocation: true,
        hasMultiplePhotos: false,
        isEmailVerified: true,
        hasPhoneNumber: false,
      ),
      preferences: UserPreferences(
        ageRange: AgeRange(start: 25, end: 35),
        maxDistance: 50,
        preferredInterests: const ['Music', 'Travel'],
        showOnlyVerified: false,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    
    _mockUsers['mock_user_123'] = mockUser;
    return Stream.value(mockUser);
  }
  
  Future<void> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockUsers[user.id] = user;
  }
  
  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockUsers[user.id] = user;
  }
  
  Future<void> deleteUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockUsers.remove(userId);
  }
}
