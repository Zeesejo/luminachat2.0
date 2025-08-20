import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'core/config/environment.dart';
import 'core/services/remote_config_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // On Android, google-services.json handles auto config.
  // On other platforms (including tests), use DefaultFirebaseOptions.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Fallback to default initialize for platforms with auto config
    try { await Firebase.initializeApp(); } catch (_) {}
  }
  // Remote Config and Analytics init
  await RemoteConfigService.instance.init(debug: !kReleaseMode);
  
  // Initialize dependency injection
  await configureDependencies();
  
  // Initialize shared preferences
  await SharedPreferences.getInstance();

  // In dev builds, optionally force sign-out so app starts on auth flow
  // This avoids landing on Home due to a previously cached Firebase session
  // when debugging login/sign-up.
  if (!kReleaseMode && Environment.useFirebase && Environment.forceLogoutOnStartup) {
    try {
      await FirebaseCrashlytics.instance.log('Forcing sign-out on startup');
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Non-fatal
    }
  }
  
  // Configure system UI
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set up crash reporting
  if (kReleaseMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  
  runApp(
    const ProviderScope(
      child: LuminaChatApp(),
    ),
  );
}

class LuminaChatApp extends ConsumerWidget {
  const LuminaChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(themeProvider);
    // Optionally set user properties if logged in (only when Firebase initialized)
    if (Firebase.apps.isNotEmpty) {
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          // lightweight properties
          await FirebaseAnalytics.instance.setUserId(id: user.uid);
        }
      });
    }
    
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
