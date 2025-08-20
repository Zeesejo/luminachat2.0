class AppConstants {
  // App Info
  static const String appName = 'Lumina Chat';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'The most sophisticated personality-matching real-time chat application';
  
  // API & Database
  static const String baseUrl = 'https://api.luminachat.com';
  static const String firestoreUsersCollection = 'users';
  static const String firestoreChatsCollection = 'chats';
  static const String firestoreMessagesCollection = 'messages';
  static const String firestoreMatchesCollection = 'matches';
  
  // Storage
  static const String storageProfileImages = 'profile_images';
  static const String storageChatImages = 'chat_images';
  static const String storageVoiceMessages = 'voice_messages';
  static const String storageChatFiles = 'chat_files';
  
  // SharedPreferences Keys
  static const String isFirstTimeKey = 'is_first_time';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String locationPermissionKey = 'location_permission';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String personalityTestCompletedKey = 'personality_test_completed';
  
  // MBTI Personality Types
  static const List<String> mbtiTypes = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];
  
  // Interest Categories
  static const List<String> interestCategories = [
    'Sports & Fitness',
    'Music & Arts',
    'Technology',
    'Travel',
    'Cooking',
    'Reading',
    'Movies & TV',
    'Gaming',
    'Photography',
    'Nature & Outdoors',
    'Fashion',
    'Business',
    'Health & Wellness',
    'Education',
    'Volunteering',
    'Pets',
    'Dancing',
    'Writing',
    'Science',
    'Politics',
    'Religion',
    'Meditation',
    'Yoga',
    'Running',
    'Cycling',
    'Swimming',
    'Hiking',
    'Rock Climbing',
    'Skiing',
    'Surfing',
    'Basketball',
    'Soccer',
    'Tennis',
    'Golf',
    'Baseball',
    'Football',
    'Volleyball',
    'Martial Arts',
    'Boxing',
    'Weightlifting',
    'Crossfit',
    'Pilates',
    'Zumba',
    'Painting',
    'Drawing',
    'Sculpture',
    'Pottery',
    'Jewelry Making',
    'Knitting',
    'Sewing',
    'Woodworking',
  ];
  
  // Age Ranges
  static const int minAge = 18;
  static const int maxAge = 99;
  
  // Distance Ranges (in kilometers)
  static const double minDistance = 1.0;
  static const double maxDistance = 100.0;
  static const double defaultDistance = 25.0;
  
  // Message Limits
  static const int maxMessageLength = 1000;
  static const int maxVoiceMessageDuration = 300; // 5 minutes in seconds
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 24.0;
  
  // Profile Completion Weights
  static const int profilePhotoWeight = 25;
  static const int bioWeight = 15;
  static const int interestsWeight = 20;
  static const int personalityWeight = 25;
  static const int preferencesWeight = 15;
  
  // Matching Algorithm Weights
  static const double personalityCompatibilityWeight = 0.4;
  static const double sharedInterestsWeight = 0.3;
  static const double locationProximityWeight = 0.2;
  static const double ageCompatibilityWeight = 0.1;
  
  // Notification Types
  static const String newMatchNotification = 'new_match';
  static const String newMessageNotification = 'new_message';
  static const String likeReceivedNotification = 'like_received';
  static const String profileViewNotification = 'profile_view';
  
  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Please check your internet connection.';
  static const String authErrorMessage = 'Authentication failed. Please try again.';
  static const String permissionErrorMessage = 'Permission denied. Please enable in settings.';
  
  // Success Messages
  static const String profileUpdatedMessage = 'Profile updated successfully!';
  static const String messageDeliveredMessage = 'Message delivered';
  static const String matchFoundMessage = 'It\'s a match! 🎉';
  static const String photoUploadedMessage = 'Photo uploaded successfully!';
}

// Image Assets
class AppImages {
  static const String logo = 'assets/images/logo_splash_large.png';
  static const String logoAnimated = 'assets/animations/logo_animation.json';
  static const String onboarding1 = 'assets/images/onboarding_1.png';
  static const String onboarding2 = 'assets/images/onboarding_2.png';
  static const String onboarding3 = 'assets/images/onboarding_3.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String noMatches = 'assets/images/no_matches.png';
  static const String noMessages = 'assets/images/no_messages.png';
  static const String welcomeIllustration = 'assets/images/welcome.png';
  static const String personalityTest = 'assets/images/personality_test.png';
}

// Lottie Animations
class AppAnimations {
  static const String loading = 'assets/animations/loading.json';
  static const String success = 'assets/animations/success.json';
  static const String error = 'assets/animations/error.json';
  static const String heartBeat = 'assets/animations/heart_beat.json';
  static const String confetti = 'assets/animations/confetti.json';
  static const String typing = 'assets/animations/typing.json';
  static const String waveform = 'assets/animations/waveform.json';
}

// Sound Assets
class AppSounds {
  static const String notification = 'assets/sounds/notification.mp3';
  static const String messageReceived = 'assets/sounds/message_received.mp3';
  static const String messageSent = 'assets/sounds/message_sent.mp3';
  static const String matchFound = 'assets/sounds/match_found.mp3';
  static const String likeReceived = 'assets/sounds/like_received.mp3';
}
