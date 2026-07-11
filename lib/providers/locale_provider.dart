import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Populate from the LocalizationService (which reads SettingsManager +
  /// SharedPreferences fallback).  Call once at startup.
  Future<void> loadLocale() async {
    final loaded = await localizationService.loadLocale();
    if (loaded != _locale) {
      _locale = loaded;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await localizationService.saveLocale(locale);
  }

  void toggleLocale() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('mr'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
