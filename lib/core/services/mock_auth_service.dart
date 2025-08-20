import 'dart:async';

class MockAuthService {
  // Mock user for testing
  static const String mockUserId = 'mock_user_123';
  
  Stream<String?> get authStateChanges {
    return Stream.value(mockUserId);
  }
  
  String? get currentUserId => mockUserId;
  
  bool get isAuthenticated => true;
  
  Future<void> signOut() async {
    // Mock sign out
  }
  
  Future<String?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Mock successful login
    return mockUserId;
  }
  
  Future<String?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Mock successful registration
    return mockUserId;
  }
  
  Future<String?> signInWithGoogle() async {
    // Mock Google sign in
    return mockUserId;
  }
  
  Future<String?> signInWithFacebook() async {
    // Mock Facebook sign in
    return mockUserId;
  }
}
