import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUsername = 'username';
  static const String _keyLoggedIn = 'is_logged_in';

  SharedPreferences? _cached;

  Future<SharedPreferences> _get() async {
    _cached ??= await SharedPreferences.getInstance();
    return _cached!;
  }

  Future<void> setRememberMe(bool value) async {
    final prefs = await _get();
    await prefs.setBool(_keyRememberMe, value);
  }

  Future<bool> getRememberMe() async {
    final prefs = await _get();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  Future<void> setUsername(String value) async {
    final prefs = await _get();
    await prefs.setString(_keyUsername, value);
  }

  Future<String> getUsername() async {
    final prefs = await _get();
    return prefs.getString(_keyUsername) ?? '';
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await _get();
    await prefs.setBool(_keyLoggedIn, value);
  }

  Future<bool> getLoggedIn() async {
    final prefs = await _get();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<void> clearAuth() async {
    final prefs = await _get();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyUsername);
  }

  Future<void> clearAll() async {
    final prefs = await _get();
    await prefs.clear();
  }
}
