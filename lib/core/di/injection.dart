import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart' hide Environment;

import '../config/environment.dart';
import '../services/mock_auth_service.dart';
import '../services/mock_user_service.dart';
import '../services/location_service.dart';
import '../services/matching_service.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  if (Environment.useFirebase) {
    // Register all Firebase-backed services via Injectable
    getIt.init();
  } else {
    // Register mock implementations for development
    getIt.registerSingleton<MockAuthService>(MockAuthService());
    getIt.registerSingleton<MockUserService>(MockUserService());

    // Services usable without Firebase
    getIt.registerSingleton<LocationService>(LocationService());
    getIt.registerSingleton<MatchingService>(MatchingService());
  }
}
