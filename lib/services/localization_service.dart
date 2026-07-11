import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class LocalizationService {
  static const String _localePrefKey = 'app_locale';

  static final LocalizationService _instance = LocalizationService._();
  static LocalizationService get instance => _instance;
  LocalizationService._();

  Locale? _cachedLocale;

  Locale get currentLocale => _cachedLocale ?? const Locale('en');

  /// Load the saved locale.  Priority:
  ///   1. Backend SettingsManager (via ApiService)
  ///   2. SharedPreferences (offline cache)
  ///   3. English (fallback)
  Future<Locale> loadLocale() async {
    if (_cachedLocale != null) return _cachedLocale!;

    Locale locale;

    // 1. Try backend
    try {
      final settings = await ApiService.getSettings();
      final code = settings['language'] as String?;
      if (code != null && _isSupported(code)) {
        locale = Locale(code);
        _cachedLocale = locale;
        await _persistLocal(code);
        return locale;
      }
    } catch (_) {
      // Backend unavailable — fall through
    }

    // 2. Try SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final localCode = prefs.getString(_localePrefKey);
    if (localCode != null && _isSupported(localCode)) {
      locale = Locale(localCode);
      _cachedLocale = locale;
      return locale;
    }

    // 3. Fallback
    locale = const Locale('en');
    _cachedLocale = locale;
    await _persistLocal('en');
    return locale;
  }

  /// Persist the locale both locally (SharedPreferences) and on the
  /// backend (SettingsManager).  Backend persistence is best-effort
  /// and will not throw on failure.
  Future<void> saveLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) return;

    _cachedLocale = locale;

    // Local — synchronous fire-and-forget
    unawaited(_persistLocal(locale.languageCode));

    // Backend — fire-and-forget, never throw
    unawaited(_syncToBackend(locale.languageCode));
  }

  // ── Private helpers ──────────────────────────────────

  bool _isSupported(String code) => code == 'en' || code == 'mr';

  Future<void> _persistLocal(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, code);
  }

  Future<void> _syncToBackend(String code) async {
    try {
      await ApiService.updateSettings({'language': code});
    } catch (_) {
      // Best-effort only
    }
  }
}

/// Shorthand for `LocalizationService.instance`.
LocalizationService get localizationService => LocalizationService.instance;
