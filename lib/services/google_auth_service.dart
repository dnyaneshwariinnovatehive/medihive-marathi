import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class GoogleAuthService {
  // Lazy initialization — GoogleSignIn is NOT created on web
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _signIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: [
        drive.DriveApi.driveFileScope,
      ],
    );
    return _googleSignIn!;
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _keyAccessToken = 'google_drive_access_token';
  static const String _keyIdToken = 'google_drive_id_token';

  // Singleton instance
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Initialize Google Sign-In (skip on web)
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await _signIn.signInSilently();
    } catch (e) {
      debugPrint('Auth init skipped: $e');
    }
  }

  /// Gets the current signed-in account, if any.
  GoogleSignInAccount? get currentUser =>
      kIsWeb ? null : _signIn.currentUser;

  /// Signs in a user with their Google Account.
  /// Requests the minimum drive.file scope required for local backup sync.
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    if (kIsWeb) return null;
    try {
      // Force account selection to avoid auto-sign in with incorrect scope
      final account = await _signIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.accessToken != null) {
          await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
        }
        if (auth.idToken != null) {
          await _secureStorage.write(key: _keyIdToken, value: auth.idToken);
        }
      }
      return account;
    } catch (e) {
      rethrow;
    }
  }

  /// Signs the user out of the application and clears secure credentials.
  Future<void> signOut() async {
    if (kIsWeb) return;
    await _signIn.signOut();
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyIdToken);
  }

  /// Checks if a user is currently signed in.
  /// Restores session silently if token/credentials exist.
  Future<bool> isSignedIn() async {
    if (kIsWeb) return false;
    if (_signIn.currentUser != null) {
      return true;
    }
    try {
      final account = await _signIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        if (auth.accessToken != null) {
          await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
        }
        return true;
      }
    } catch (_) {
      // Ignored: silent sign-in failed (e.g., first time opening app)
    }
    return false;
  }

  /// Retrieves authorization headers required for Google Drive API REST requests.
  /// Automatically handles silent token refresh through the Google Sign-In SDK.
  Future<Map<String, String>> getAuthHeaders() async {
    if (kIsWeb) throw UnsupportedError('Google Auth not supported on web');
    var account = _signIn.currentUser;
    account ??= await _signIn.signInSilently();
    if (account == null) {
      throw Exception('User is not signed in to Google.');
    }

    final auth = await account.authentication;
    final headers = await account.authHeaders;

    if (auth.accessToken != null) {
      await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
    }

    return headers;
  }

  /// Safely gets the secure cached access token.
  Future<String?> getCachedAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }
}
