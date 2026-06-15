import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _hasLoadedCredentials = false;
  bool _rememberMe = false;
  String _username = '';
  String _password = '';
  AppUser? _currentUser;

  AuthProvider() {
    loadSavedCredentials();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get hasLoadedCredentials => _hasLoadedCredentials;
  bool get rememberMe => _rememberMe;
  String get username => _username;
  String get password => _password;
  AppUser? get currentUser => _currentUser;

  // Keep compatibility alias
  bool get isLoggedIn => _isAuthenticated;

  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<bool> signIn() async {
    final username = _username.trim();
    final password = _password.trim();

    _isLoading = true;
    notifyListeners();

    final user = await _authService.login(username, password);

    if (user != null) {
      _isAuthenticated = true;
      _currentUser = user;
      await _storageService.setLoggedIn(_rememberMe);
      if (_rememberMe) {
        await _storageService.setRememberMe(true);
        await _storageService.setUsername(username);
      } else {
        await _storageService.clearAuth();
      }
    }

    _isLoading = false;
    notifyListeners();
    return user != null;
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.signInWithGoogle();

    if (user != null) {
      _isAuthenticated = true;
      _currentUser = user;
      await _storageService.setLoggedIn(true);
    }

    _isLoading = false;
    notifyListeners();
    return user != null;
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
    _currentUser = null;
    _username = '';
    _password = '';
    await _authService.logout();
    await _storageService.clearAuth();
    notifyListeners();
  }

  // Alias for backward compatibility
  Future<bool> login() => signIn();
  Future<void> logout() => signOut();

  Future<void> loadSavedCredentials() async {
    _rememberMe = await _storageService.getRememberMe();
    final wasLoggedIn = await _storageService.getLoggedIn();
    
    if (wasLoggedIn) {
      // Try silent sign in
      final user = await _authService.signInSilently();
      if (user != null) {
        _isAuthenticated = true;
        _currentUser = user;
      } else if (_rememberMe) {
        _username = await _storageService.getUsername();
        // Since we mock login, just let them in if remember me
        _isAuthenticated = true;
        _currentUser = AppUser(id: '1', name: 'Dr. $_username', email: '$_username@medihive.com');
      }
    }
    _hasLoadedCredentials = true;
    notifyListeners();
  }
}
