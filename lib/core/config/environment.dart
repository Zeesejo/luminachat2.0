/// Global build-time environment configuration
class Environment {
  /// Toggle Firebase usage. Set to true after configuring Firebase.
  static const bool useFirebase = true;

  /// Development helper: when true (and not in release mode), the app will
  /// sign out any persisted Firebase session on startup so you always land on
  /// the login/sign up flow. Keep this false for release builds.
  static const bool forceLogoutOnStartup = true;
}
