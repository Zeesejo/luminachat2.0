import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  Future<void> init({bool debug = true}) async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: debug ? const Duration(seconds: 0) : const Duration(hours: 12),
    ));
    await _rc.setDefaults(const {
      'enable_calls': true,
      'enable_video_calls': true,
      'require_min_interests': 3,
      'discover_page_size': 20,
    });
    await _rc.fetchAndActivate();
  }

  bool getBool(String key) => _rc.getBool(key);
  int getInt(String key) => _rc.getInt(key);
  double getDouble(String key) => _rc.getDouble(key);
  String getString(String key) => _rc.getString(key);
}
