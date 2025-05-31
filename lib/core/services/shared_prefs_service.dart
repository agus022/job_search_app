import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static SharedPreferences? _prefs;

  // Inicializar (llamar en main)
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Onboarding
  static bool get isFirstLaunch => _prefs?.getBool('onboarding_visto') ?? true;
  static Future<void> setFirstLaunch(bool value) async {
    await _prefs?.setBool('onboarding_visto', value);
  }

  //Modificaciones del tema
  static bool get isDarkMode => _prefs?.getBool('dark_mode') ?? false;
  static Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool('dark_mode', value);
  }

  // Futuro (si queremos guardar más datos)
  static String? get userToken => _prefs?.getString('user_token');
  static Future<void> setUserToken(String token) async {
    await _prefs?.setString('user_token', token);
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
