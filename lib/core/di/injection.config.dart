// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:lumina_chat/core/services/auth_service.dart' as _i31;
import 'package:lumina_chat/core/services/chat_service.dart' as _i140;
import 'package:lumina_chat/core/services/location_service.dart' as _i636;
import 'package:lumina_chat/core/services/matching_service.dart' as _i458;
import 'package:lumina_chat/core/services/notification_service.dart' as _i554;
import 'package:lumina_chat/core/services/storage_service.dart' as _i801;
import 'package:lumina_chat/core/services/user_service.dart' as _i440;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i31.AuthService>(() => _i31.AuthService());
    gh.singleton<_i140.ChatService>(() => _i140.ChatService());
    gh.singleton<_i636.LocationService>(() => _i636.LocationService());
    gh.singleton<_i458.MatchingService>(() => _i458.MatchingService());
    gh.singleton<_i554.NotificationService>(() => _i554.NotificationService());
    gh.singleton<_i801.StorageService>(() => _i801.StorageService());
    gh.singleton<_i440.UserService>(() => _i440.UserService());
    return this;
  }
}
