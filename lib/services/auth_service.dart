import 'package:google_sign_in/google_sign_in.dart';

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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata', // For backup
    ],
  );

  /// Standard email/password mock login
  Future<AppUser?> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, validate with backend. Here we just return a mock user.
    if (username.isNotEmpty && password.isNotEmpty) {
      return AppUser(id: '1', name: 'Dr. $username', email: '$username@medihive.com');
    }
    return null;
  }

  /// Google Sign In
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        return AppUser(
          id: account.id,
          name: account.displayName ?? 'Doctor',
          email: account.email,
          photoUrl: account.photoUrl,
        );
      }
    } catch (e) {
      print('Google Sign In Error: $e');
    }
    return null;
  }

  /// Logout from Google if signed in
  Future<void> logout() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('Google Sign Out Error: $e');
    }
  }

  /// Silent sign in for Google
  Future<AppUser?> signInSilently() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account != null) {
        return AppUser(
          id: account.id,
          name: account.displayName ?? 'Doctor',
          email: account.email,
          photoUrl: account.photoUrl,
        );
      }
    } catch (e) {
      print('Silent Sign In Error: $e');
    }
    return null;
  }
}
