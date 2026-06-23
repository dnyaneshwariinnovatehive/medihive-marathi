import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'google_auth_service.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });
}

class AuthService {
  /// Standard email/password login via Flask API.
  /// If the server is unreachable, validates against credentials
  /// stored in assets/.env (LOCAL_USERNAME / LOCAL_PASSWORD).
  Future<AppUser?> login(String username, String password) async {
    try {
      final data = await ApiService.login(username, password);
      final user = data['user'] as Map<String, dynamic>;
      return AppUser(
        id: user['id']?.toString() ?? '',
        name: user['name']?.toString() ?? 'Doctor',
        email: '${user['username']}@medihive.com',
      );
    } catch (e) {
      debugPrint('AuthService.login: API failed, falling back to local auth: $e');
      final envUser = dotenv.env['LOCAL_USERNAME'];
      final envPass = dotenv.env['LOCAL_PASSWORD'];
      if (username == envUser && password == envPass) {
        return AppUser(
          id: '1',
          name: 'Dr. $username',
          email: '$username@medihive.com',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final savedPass = prefs.getString('app_password');
      final savedUser = prefs.getString('app_username');
      if (username == (savedUser ?? envUser) && password == savedPass) {
        return AppUser(
          id: '1',
          name: 'Dr. $username',
          email: '$username@medihive.com',
        );
      }
      return null;
    }
  }

  /// Register a new user via Flask API.
  /// Falls back to local registration in SharedPreferences.
  Future<AppUser?> register(String username, String password, {String name = 'Doctor'}) async {
    try {
      final data = await ApiService.register(username, password, name: name);
      final user = data['user'] as Map<String, dynamic>;
      return AppUser(
        id: user['id']?.toString() ?? '',
        name: user['name']?.toString() ?? 'Doctor',
        email: '${user['username']}@medihive.com',
      );
    } catch (e) {
      debugPrint('AuthService.register: API failed, saving locally: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_username', username);
      await prefs.setString('app_password', password);
      return AppUser(
        id: '1',
        name: name,
        email: '$username@medihive.com',
      );
    }
  }

  /// Google Sign In — delegates to GoogleAuthService (single shared instance)
  Future<AppUser?> signInWithGoogle() async {
    try {
      final account = await GoogleAuthService().signInWithGoogle();
      if (account != null) {
        return AppUser(
          id: account.id,
          name: account.displayName ?? 'Doctor',
          email: account.email,
          photoUrl: account.photoUrl,
        );
      }
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
    }
    return null;
  }

  /// Silent sign in for Google
  Future<AppUser?> signInSilently() async {
    try {
      final signedIn = await GoogleAuthService().isSignedIn();
      if (signedIn) {
        final account = GoogleAuthService().currentUser;
        if (account != null) {
          return AppUser(
            id: account.id,
            name: account.displayName ?? 'Doctor',
            email: account.email,
            photoUrl: account.photoUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('AuthService.signInSilently error: $e');
    }
    return null;
  }

  /// Logout
  Future<void> logout() async {
    await ApiService.clearToken();
    try {
      await GoogleAuthService().signOut();
    } catch (e) {
      debugPrint('AuthService.logout: Google sign-out error: $e');
    }
  }
}
