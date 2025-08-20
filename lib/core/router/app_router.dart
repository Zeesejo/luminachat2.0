import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/environment.dart';
import '../services/user_service.dart' as user_service;
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/onboarding/presentation/pages/choose_username_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/matching/presentation/pages/home_page.dart';
import '../../features/matching/presentation/pages/match_details_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../shared/widgets/main_navigation.dart';
import '../services/auth_service.dart';
import '../../features/onboarding/presentation/pages/onboarding_coordinator_page.dart';

// Route Names
class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String chooseUsername = '/choose-username';
  static const String personalityTest = '/personality-test';
  static const String profileSetup = '/profile-setup';
  static const String comprehensiveOnboarding = '/comprehensive-onboarding';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String chatList = '/chats';
  static const String chat = '/chat';
  static const String matchDetails = '/match-details';
  static const String settings = '/settings';
  static const String mainNavigation = '/main';
}

final routerProvider = Provider<GoRouter>((ref) {
  const useFirebase = Environment.useFirebase;
  final authService = useFirebase ? ref.watch(authServiceProvider) : null;
  final currentUser = useFirebase ? ref.watch(user_service.currentUserProvider) : null;
  
  // Make router reactive to auth state changes
  final Listenable refresher = useFirebase
      ? GoRouterRefreshStream(authService!.authStateChanges)
      : ValueNotifier<int>(0);

  return GoRouter(
    initialLocation: useFirebase ? AppRoutes.splash : AppRoutes.welcome,
    refreshListenable: refresher,
    redirect: (context, state) {
      if (!useFirebase) return null; // Skip auth redirects in mock mode
      
      final user = authService!.currentUser;
      final isLoggedIn = user != null;
      final isVerified = user?.emailVerified ?? false;
      final path = state.uri.path;
      final qp = state.uri.queryParameters;
      // Temporary bypass: when navigating right after onboarding, allow forcing main route
      final forceBypass = qp['force'] == 'true';
      if (forceBypass) return null;
      final isOnSplash = path == AppRoutes.splash;
      final isOnForgot = path == AppRoutes.forgotPassword;
      final isOnVerify = path == AppRoutes.verifyEmail;
      final isOnOnboarding = path == AppRoutes.comprehensiveOnboarding;
      const isOnAuthList = <String>[
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.welcome,
      ];
      final isOnAuth = isOnAuthList.contains(path);

      // Always allow Forgot Password without redirecting
      if (isOnForgot) return null;

      // If not logged in and navigating to verify page, send to welcome
      if (!isLoggedIn && isOnVerify) {
        return AppRoutes.welcome;
      }

      // If not logged in and not on auth pages, redirect to welcome
      if (!isLoggedIn && !isOnAuth && !isOnForgot && !isOnSplash) {
        return AppRoutes.welcome;
      }

      // If logged in but not verified, force to verify page (except forgot/splash/choose-username)
      if (isLoggedIn && !isVerified && !isOnVerify && !isOnForgot && !isOnSplash && path != AppRoutes.chooseUsername) {
        return AppRoutes.verifyEmail;
      }

      // If logged in and verified, check if profile is complete
      if (isLoggedIn && isVerified && !isOnAuth && !isOnVerify && !isOnOnboarding) {
        // Don't redirect if user is already in main navigation areas
        final mainAppRoutes = [
          AppRoutes.home,
          AppRoutes.chatList,
          AppRoutes.profile,
          AppRoutes.settings,
          AppRoutes.editProfile,
          AppRoutes.mainNavigation
        ];
        final isInMainApp = mainAppRoutes.any((route) => path == route || path.startsWith('$route/')) ||
                           path.startsWith('/main') ||
                           path.startsWith('/chat/') ||
                           path.startsWith('/match-details');
        
        // Safely extract user data from AsyncValue
        final userData = currentUser?.when(
          data: (user) => user,
          loading: () => null,
          error: (error, stack) => null,
        );
        
        if (userData == null && !isInMainApp) {
          // User doesn't exist in Firestore or still loading, need onboarding
          return AppRoutes.comprehensiveOnboarding;
        }
        
        // Only check for onboarding completion if not already in main app
        if (userData != null && !isInMainApp) {
          // Check if essential onboarding is complete - location is optional
          final completion = userData.profileCompletion;
          final needsOnboarding = !completion.hasProfilePhoto || 
                                !completion.hasInterests || 
                                !completion.hasPersonalityTest;
                                // Location is not required for completion
                                
          if (needsOnboarding) {
            return AppRoutes.comprehensiveOnboarding;
          }
        }
      }

      // If logged in and verified but on auth or verify pages, go to main
      if (isLoggedIn && isVerified && (isOnAuth || isOnVerify)) {
        return AppRoutes.mainNavigation;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: AppRoutes.chooseUsername,
        builder: (context, state) => const ChooseUsernamePage(),
      ),
      GoRoute(
        path: AppRoutes.personalityTest,
        builder: (context, state) => const OnboardingCoordinatorPage(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.comprehensiveOnboarding,
        builder: (context, state) {
      // Default to allowing skip when param is absent
      final allowSkip = state.uri.queryParameters['allowSkip'] == null
        ? true
        : state.uri.queryParameters['allowSkip'] == 'true';
          return OnboardingCoordinatorPage(allowSkip: allowSkip);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.mainNavigation,
            redirect: (context, state) {
              final query = state.uri.query;
              // Preserve query params so force=true survives
              return query.isNotEmpty
                  ? '${AppRoutes.home}?$query'
                  : AppRoutes.home;
            },
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.chatList,
            builder: (context, state) => const ChatListPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.editProfile,
            builder: (context, state) => const EditProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.chat}/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final otherUserId = state.uri.queryParameters['otherUserId'];
          return ChatPage(
            chatId: chatId,
            otherUserId: otherUserId,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.matchDetails}/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return MatchDetailsPage(userId: userId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Notifier that triggers GoRouter to refresh when a stream emits.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
