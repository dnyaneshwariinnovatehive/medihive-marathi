import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import '../services/google_auth_service.dart';
import '../services/google_drive_sync_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = false;

  // Doctor Profile
  String _doctorName = 'Dr. Rajas Gavas';
  String _doctorSpecialty = 'General Physician';
  String _doctorLicense = 'I-107200-A';
  String _doctorEmail = 'dr.rajas@gmail.com';
  String _doctorPhone = '+91 98765 43210';
  String _doctorProfileImage = '';

  // Clinic Info
  String _clinicName = 'Shree Clinic';
  String _clinicPhone = '+91 22 2345 6789';
  String _clinicAddress = 'Suite 101, Medical Plaza, Mumbai';
  String _clinicHours = '09:00 AM - 01:00 PM, 04:00 PM - 08:00 PM';
  String _clinicWebsite = '';

  // Email Config
  String _emailSender = 'MediHive Alerts';
  String _emailSmtp = 'smtp.gmail.com';
  String _emailPort = '587';
  String _emailUser = 'alerts@medihive.com';
  String _emailPass = '';

  // Google Sign-In & Backup state (lazy to avoid web crash)
  GoogleAuthService? _googleAuthServiceInstance;
  GoogleAuthService get _googleAuthService {
    _googleAuthServiceInstance ??= GoogleAuthService();
    return _googleAuthServiceInstance!;
  }
  bool _isGoogleSigningIn = false;
  GoogleSignInAccount? _googleUser;
  String? _googleAuthError;
  String _lastSyncTime = 'Never';
  bool _isSyncEnabled = false;
  bool _isSyncing = false;
  StreamSubscription? _googleAuthSub;
  int _authRefreshAttempts = 0;

  // Getters
  bool get darkMode => _darkMode;
  String get doctorName => _doctorName;
  String get doctorSpecialty => _doctorSpecialty;
  String get doctorLicense => _doctorLicense;
  String get doctorEmail => _doctorEmail;
  String get doctorPhone => _doctorPhone;
  String get doctorProfileImage => _doctorProfileImage;

  String get clinicName => _clinicName;
  String get clinicPhone => _clinicPhone;
  String get clinicAddress => _clinicAddress;
  String get clinicHours => _clinicHours;
  String get clinicWebsite => _clinicWebsite;

  String get emailSender => _emailSender;
  String get emailSmtp => _emailSmtp;
  String get emailPort => _emailPort;
  String get emailUser => _emailUser;
  String get emailPass => _emailPass;

  // Google Getters
  bool get isGoogleConnected => _googleUser != null;
  bool get isGoogleSigningIn => _isGoogleSigningIn;
  GoogleSignInAccount? get googleUser => _googleUser;
  String? get googleAuthError => _googleAuthError;
  String get lastSyncTime => _lastSyncTime;
  bool get isSyncEnabled => _isSyncEnabled;
  bool get isSyncing => _isSyncing;

  SettingsProvider() {
    _loadSettings();
    _checkGoogleSignInStatus();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    try {
      _googleAuthSub = _googleAuthService.onAuthStateChanged.listen((account) {
        _googleUser = account;
        if (account == null) {
          _isSyncEnabled = false;
          _isSyncing = false;
          _googleAuthError = null;
        } else {
          _isSyncEnabled = true;
        }
        notifyListeners();
      });
    } catch (_) {}
  }

  Future<void> _checkGoogleSignInStatus() async {
    try {
      final signedIn = await _googleAuthService.isSignedIn();
      if (signedIn) {
        _googleUser = _googleAuthService.currentUser;
        final prefs = await SharedPreferences.getInstance();
        _lastSyncTime = prefs.getString('lastSyncTime') ?? 'Never';
        _isSyncEnabled = prefs.getBool('isSyncEnabled') ?? false;
      }
      _googleAuthError = null;
      notifyListeners();
    } catch (e) {
      _googleAuthError = null;
      notifyListeners();
    }
  }

  Future<void> signInGoogle() async {
    _isGoogleSigningIn = true;
    _googleAuthError = null;
    notifyListeners();

    try {
      final account = await _googleAuthService.signInWithGoogle();
      _googleUser = account;
      _authRefreshAttempts = 0;
      if (account != null) {
        _isSyncEnabled = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSyncEnabled', true);
      }
    } catch (e) {
      _googleAuthError = 'Sign-in failed: $e';
    } finally {
      _isGoogleSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOutGoogle() async {
    _googleAuthError = null;
    notifyListeners();

    try {
      await _googleAuthService.signOut();
      _googleUser = null;
      _isSyncEnabled = false;
      _authRefreshAttempts = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSyncEnabled', false);
      await prefs.remove('lastSyncTime');
      _lastSyncTime = 'Never';
    } catch (e) {
      _googleAuthError = 'Disconnect failed. Please try again.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _googleAuthError = null;
    notifyListeners();

    try {
      final signedIn = await _googleAuthService.isSignedIn();
      if (!signedIn) {
        _googleAuthError = 'Please connect Google Drive first.';
        _isSyncing = false;
        notifyListeners();
        return;
      }
      _googleUser = _googleAuthService.currentUser;

      await _googleAuthService.getAuthHeaders();
      final driveService = GoogleDriveSyncService();
      await driveService.syncPendingRecords();
      _googleAuthError = null;
      _authRefreshAttempts = 0;

      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final String amPm = now.hour >= 12 ? 'PM' : 'AM';
      final int displayHour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final String minuteStr = now.minute.toString().padLeft(2, '0');
      _lastSyncTime = '${now.day} ${months[now.month - 1]} ${now.year}, ${displayHour.toString().padLeft(2, '0')}:$minuteStr $amPm';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastSyncTime', _lastSyncTime);
    } catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('auth') || errorMsg.contains('session') || errorMsg.contains('sign')) {
        if (_authRefreshAttempts < 2) {
          _authRefreshAttempts++;
          try {
            await _googleAuthService.signOut();
            final account = await _googleAuthService.signInWithGoogle();
            if (account != null) {
              _googleUser = account;
              _isSyncEnabled = true;
              _isSyncing = false;
              _googleAuthError = null;
              notifyListeners();
              return;
            }
          } catch (_) {}
        }
        _googleAuthError = 'Session expired. Please reconnect Google Drive.';
      } else if (errorMsg.contains('quota')) {
        _googleAuthError = 'Google Drive storage full. Please free up space.';
      } else if (errorMsg.contains('network') || errorMsg.contains('socket')) {
        _googleAuthError = 'Network error. Sync will retry automatically when connected.';
      } else {
        _googleAuthError = 'Sync failed. Please try again.';
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _darkMode = prefs.getBool('darkMode') ?? false;
      AppTheme.isDarkMode = _darkMode;
      _doctorName = prefs.getString('doctorName') ?? 'Dr. Rajas Gavas';
      _doctorSpecialty = prefs.getString('doctorSpecialty') ?? 'General Physician';
      _doctorLicense = prefs.getString('doctorLicense') ?? 'I-107200-A';
      _doctorEmail = prefs.getString('doctorEmail') ?? 'dr.rajas@gmail.com';
      _doctorPhone = prefs.getString('doctorPhone') ?? '+91 98765 43210';
      _doctorProfileImage = prefs.getString('doctorProfileImage') ?? '';
      _clinicName = prefs.getString('clinicName') ?? 'Shree Clinic';
      _clinicPhone = prefs.getString('clinicPhone') ?? '+91 22 2345 6789';
      _clinicAddress = prefs.getString('clinicAddress') ?? 'Suite 101, Medical Plaza, Mumbai';
      _clinicHours = prefs.getString('clinicHours') ?? '09:00 AM - 01:00 PM, 04:00 PM - 08:00 PM';
      _clinicWebsite = prefs.getString('clinicWebsite') ?? '';
      _emailSender = prefs.getString('emailSender') ?? 'MediHive Alerts';
      _emailSmtp = prefs.getString('emailSmtp') ?? 'smtp.gmail.com';
      _emailPort = prefs.getString('emailPort') ?? '587';
      _emailUser = prefs.getString('emailUser') ?? 'alerts@medihive.com';
      _emailPass = prefs.getString('emailPass') ?? '';
      notifyListeners();
    } catch (_) {
      // Silently handle — settings will use defaults
    }
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    AppTheme.isDarkMode = _darkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
  }

  Future<void> updateDoctorProfile({
    required String name,
    required String specialty,
    required String license,
    required String email,
    required String phone,
  }) async {
    _doctorName = name;
    _doctorSpecialty = specialty;
    _doctorLicense = license;
    _doctorEmail = email;
    _doctorPhone = phone;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctorName', name);
    await prefs.setString('doctorSpecialty', specialty);
    await prefs.setString('doctorLicense', license);
    await prefs.setString('doctorEmail', email);
    await prefs.setString('doctorPhone', phone);
  }

  Future<void> updateDoctorProfileImage(String base64Image) async {
    _doctorProfileImage = base64Image;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctorProfileImage', base64Image);
  }

  Future<void> updateClinicInfo({
    required String name,
    required String phone,
    required String address,
    required String hours,
    String website = '',
  }) async {
    _clinicName = name;
    _clinicPhone = phone;
    _clinicAddress = address;
    _clinicHours = hours;
    _clinicWebsite = website;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clinicName', name);
    await prefs.setString('clinicPhone', phone);
    await prefs.setString('clinicAddress', address);
    await prefs.setString('clinicHours', hours);
    await prefs.setString('clinicWebsite', website);
  }

  @override
  void dispose() {
    _googleAuthSub?.cancel();
    super.dispose();
  }

  Future<void> updateEmailConfig({
    required String sender,
    required String smtp,
    required String port,
    required String user,
    required String pass,
  }) async {
    _emailSender = sender;
    _emailSmtp = smtp;
    _emailPort = port;
    _emailUser = user;
    _emailPass = pass;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emailSender', sender);
    await prefs.setString('emailSmtp', smtp);
    await prefs.setString('emailPort', port);
    await prefs.setString('emailUser', user);
    await prefs.setString('emailPass', pass);
  }
}
